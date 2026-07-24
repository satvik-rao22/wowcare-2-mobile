import 'package:dio/dio.dart';
import 'package:timezone/timezone.dart' as tz;

import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/logger_service.dart';

/// Authoritative "now", sourced from the backend clock rather than the device.
///
/// **Why an offset, not per-call fetching.** The app reads "now" hundreds of
/// times per session (every date field default, every payload timestamp, every
/// "today" comparison). Hitting `POST /api/v1/time` on each of those is
/// impossible — it's async and would flood the network. So we sync ONCE (and
/// periodically), measure the gap between the server clock and this device's
/// clock, and then serve `now()` synchronously by adding that offset to the
/// still-ticking device clock. The device clock keeps time accurately between
/// syncs; we only correct for its absolute skew.
///
/// **Fail-safe.** Until a sync succeeds — or if every sync fails — the offset is
/// zero, i.e. plain device time. A time source that can silently break every
/// date in the app must never hard-fail; the worst case is "same as before this
/// feature existed".
class ServerTimeService {
  ServerTimeService._();
  static final ServerTimeService instance = ServerTimeService._();

  /// serverUtc − deviceUtc, measured at the last successful sync.
  Duration _offset = Duration.zero;
  bool _synced = false;

  bool get isSynced => _synced;
  Duration get offset => _offset;

  /// Server-corrected current instant, in UTC. Synchronous and allocation-cheap
  /// so it's safe to call from anywhere, including widget builds.
  DateTime nowUtc() => DateTime.now().toUtc().add(_offset);

  /// Server-corrected current instant, in the device's local zone. Prefer the
  /// school-zone helpers (`SchoolZoneDateTime`) for user-facing dates.
  DateTime now() => nowUtc().toLocal();

  /// Fetches the backend clock and recomputes [_offset]. Best-effort: any
  /// failure leaves the previous offset (or zero) untouched. Safe to call
  /// repeatedly — startup, post-login, on resume.
  Future<void> sync() async {
    try {
      final client = serviceLocator<ApiClient>().client;
      final url = ApiPaths.url(ApiPaths.serverTime);

      // Bracket the request with device readings so we can subtract out the
      // round-trip: the server instant corresponds to a point in the MIDDLE of
      // the request, not when the response arrives.
      // Send the SCHOOL timezone so the server evaluates "now" in the school's
      // zone (the response `data` fields come back in that zone). The offset we
      // derive is timezone-independent regardless, because we convert the
      // response back to a UTC instant using the returned `timeZone`.
      //
      // Read straight from storage rather than via SchoolTimezoneResolver —
      // that resolver calls THIS service, so importing it here would be a cycle.
      final schoolTz =
          (await serviceLocator<StorageService>()
                      .getString(StorageKeys.schoolTimeZone) ??
                  '')
              .trim();
      final requestTimeZone = schoolTz.isNotEmpty ? schoolTz : 'UTC';

      final deviceBefore = DateTime.now().toUtc();
      final response = await client.post<dynamic>(
        url,
        data: <String, dynamic>{'timeZone': requestTimeZone},
        options: Options(validateStatus: (_) => true),
      );
      final deviceAfter = DateTime.now().toUtc();

      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        AppLogger.d('[ServerTime] sync failed: HTTP $status');
        return;
      }

      final root = response.data;
      final data = (root is Map && root['data'] is Map) ? root['data'] as Map : null;
      if (data == null) {
        AppLogger.d('[ServerTime] sync: unexpected body');
        return;
      }

      final serverUtc = _parseServerUtc(data);
      if (serverUtc == null) {
        AppLogger.d('[ServerTime] sync: could not parse server time');
        return;
      }

      // Midpoint of the two device readings ≈ the device instant that lines up
      // with the server instant.
      final deviceMid = deviceBefore.add(
        Duration(
          microseconds:
              deviceAfter.difference(deviceBefore).inMicroseconds ~/ 2,
        ),
      );
      final candidate = serverUtc.difference(deviceMid);

      // Sanity guard: a magnitude beyond a year is almost certainly a parse
      // bug, not genuine device-clock drift — reject it rather than shift every
      // date in the app by a nonsense amount.
      if (candidate.abs() > const Duration(days: 366)) {
        AppLogger.d('[ServerTime] rejecting implausible offset: $candidate');
        return;
      }

      _offset = candidate;
      _synced = true;
      AppLogger.d(
        '[ServerTime] synced — offset ${candidate.inMilliseconds}ms '
        '(server ahead of device)',
      );
    } catch (e) {
      AppLogger.d('[ServerTime] sync threw (keeping current offset): $e');
    }
  }

  /// Builds the server's UTC instant from the response `data`.
  ///
  /// Prefers the discrete components (year/month/…/milliSeconds) interpreted in
  /// the returned `timeZone`; falls back to the ISO `dateTime` string.
  DateTime? _parseServerUtc(Map data) {
    int? intOf(String key) {
      final v = data[key];
      if (v is num) return v.toInt();
      return int.tryParse('${v ?? ''}'.trim());
    }

    final year = intOf('year');
    final month = intOf('month');
    final day = intOf('day');
    final hour = intOf('hour');
    final minute = intOf('minute');
    final second = intOf('seconds') ?? 0;
    final millis = intOf('milliSeconds') ?? 0;

    if (year != null &&
        month != null &&
        day != null &&
        hour != null &&
        minute != null) {
      final loc = _location((data['timeZone'] ?? 'UTC').toString());
      return tz.TZDateTime(
        loc,
        year,
        month,
        day,
        hour,
        minute,
        second,
        millis,
      ).toUtc();
    }

    // Fallback: the ISO string, interpreted in the returned zone.
    final iso = (data['dateTime'] ?? '').toString().trim();
    if (iso.isEmpty) return null;
    final parsed = DateTime.tryParse(iso);
    if (parsed == null) return null;
    if (parsed.isUtc) return parsed;
    // `dateTime` carries no zone; treat its wall-clock as the returned zone.
    final loc = _location((data['timeZone'] ?? 'UTC').toString());
    return tz.TZDateTime(
      loc,
      parsed.year,
      parsed.month,
      parsed.day,
      parsed.hour,
      parsed.minute,
      parsed.second,
      parsed.millisecond,
    ).toUtc();
  }

  tz.Location _location(String ianaName) {
    final id = ianaName.trim().isEmpty ? 'UTC' : ianaName.trim();
    try {
      return tz.getLocation(id);
    } catch (_) {
      return tz.UTC;
    }
  }
}
