import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/core/utils/logger_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/core/utils/server_time_service.dart';

/// Loads the school's IANA timezone from the backend for use in attendance payloads.
///
/// Timestamps should remain UTC ([DateTime.toUtc] / `...Z` ISO strings). The
/// [timeZone] field tells the server which school zone applies for interpretation.
abstract final class SchoolTimezoneResolver {
  SchoolTimezoneResolver._();

  static const String fallbackTimeZone = 'UTC';
  static String _lastKnownTimeZone = fallbackTimeZone;
  static String get lastKnownTimeZone => _lastKnownTimeZone;

  static Future<String> resolveForCurrentSchool({
    required StorageService storage,
    required ApiClient apiClient,
  }) async {
    // Every date/time FIELD open, screen-init default, and submit resolves the
    // school zone through here — so this is the single point at which we pull a
    // FRESH authoritative server clock (per product: "fetch fresh when a date
    // field opens"). Awaited so the resolved "now" reflects this moment, but
    // time-boxed so a slow/hung /time call never blocks the field for long; on
    // timeout the last-synced offset (or device time) stands in.
    try {
      await ServerTimeService.instance.sync().timeout(
        const Duration(seconds: 4),
      );
    } catch (_) {
      // Non-fatal: keep the previous offset.
    }

    // The /time sync above already learned the school's real IANA zone as a
    // side effect — the backend returns `timeZone` alongside the corrected
    // clock (see ServerTimeService._parseServerUtc). Remember it BEFORE
    // doing our own independent schoolCode-keyed lookup below: that lookup
    // has its own failure modes (missing schoolCode, network error, ...),
    // and on failure must never clobber a zone we already know is correct
    // with the hardcoded UTC fallback.
    final syncedTimeZone = ServerTimeService.instance.schoolTimeZone.trim();
    final hasSyncedTimeZone =
        syncedTimeZone.isNotEmpty &&
        syncedTimeZone.toUpperCase() != fallbackTimeZone;

    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    if (schoolCode.isEmpty) {
      if (hasSyncedTimeZone) {
        AppLogger.d(
          '[SchoolTimezoneResolver] no active schoolCode, but /time sync '
          'already resolved $syncedTimeZone — using it',
        );
        _lastKnownTimeZone = syncedTimeZone;
        return syncedTimeZone;
      }
      AppLogger.w(
        '[SchoolTimezoneResolver] no active schoolCode in storage — '
        'falling back to $fallbackTimeZone',
      );
      return fallbackTimeZone;
    }

    final cachedFor =
        (await storage.getString(StorageKeys.schoolTimeZoneSchoolCode) ?? '').trim();
    final cachedTz = (await storage.getString(StorageKeys.schoolTimeZone) ?? '').trim();
    final hasUsableCachedTz =
        cachedFor == schoolCode &&
        cachedTz.isNotEmpty &&
        cachedTz.toUpperCase() != fallbackTimeZone;
    if (hasUsableCachedTz) {
      _lastKnownTimeZone = cachedTz;
      ServerTimeService.instance.setSchoolTimeZone(cachedTz);
      return cachedTz;
    }

    final tz = await fetchSchoolTimeZone(
      schoolCode: schoolCode,
      apiClient: apiClient,
    );
    if (tz.toUpperCase() != fallbackTimeZone) {
      await storage.saveString(StorageKeys.schoolTimeZoneSchoolCode, schoolCode);
      await storage.saveString(StorageKeys.schoolTimeZone, tz);
      _lastKnownTimeZone = tz;
      ServerTimeService.instance.setSchoolTimeZone(tz);
      return tz;
    }

    // Our own lookup failed. Preserve a previously resolved non-fallback
    // timezone rather than clobbering it with hardcoded UTC.
    if (cachedFor == schoolCode && cachedTz.isNotEmpty) {
      _lastKnownTimeZone = cachedTz;
      ServerTimeService.instance.setSchoolTimeZone(cachedTz);
      return cachedTz;
    }
    if (hasSyncedTimeZone) {
      AppLogger.d(
        '[SchoolTimezoneResolver] school-timezone lookup failed for '
        '$schoolCode, but /time sync already resolved $syncedTimeZone — '
        'using it instead of $fallbackTimeZone',
      );
      _lastKnownTimeZone = syncedTimeZone;
      // Deliberately do NOT call setSchoolTimeZone here — ServerTimeService
      // already holds the correct value; overwriting it with the fallback
      // is exactly the bug this branch exists to avoid.
      return syncedTimeZone;
    }
    _lastKnownTimeZone = tz;
    ServerTimeService.instance.setSchoolTimeZone(tz);
    return tz;
  }

  static Future<String> fetchSchoolTimeZone({
    required String schoolCode,
    required ApiClient apiClient,
  }) async {
    final code = schoolCode.trim();
    if (code.isEmpty) return fallbackTimeZone;
    final path = ApiPaths.schoolTimezone(code);
    final url = ApiPaths.url(path);
    try {
      final response = await apiClient.client.get<dynamic>(url);
      final root = response.data;
      if (root is Map<String, dynamic>) {
        final data = root['data'];
        if (data is Map<String, dynamic>) {
          final raw =
              (data['timeZone'] ?? data['timezone'] ?? '').toString().trim();
          if (raw.isNotEmpty) {
            _lastKnownTimeZone = raw;
            return raw;
          }
          AppLogger.w(
            '[SchoolTimezoneResolver] GET $url returned 200 but no '
            'timeZone/timezone field in data=$data — falling back to '
            '$fallbackTimeZone',
          );
        } else {
          AppLogger.w(
            '[SchoolTimezoneResolver] GET $url returned 200 but "data" '
            'was not a Map (root=$root) — falling back to $fallbackTimeZone',
          );
        }
      } else {
        AppLogger.w(
          '[SchoolTimezoneResolver] GET $url returned a non-Map body '
          '(root=$root) — falling back to $fallbackTimeZone',
        );
      }
    } catch (e) {
      AppLogger.w(
        '[SchoolTimezoneResolver] GET $url threw $e — falling back to '
        '$fallbackTimeZone',
      );
    }
    _lastKnownTimeZone = fallbackTimeZone;
    return fallbackTimeZone;
  }
}
