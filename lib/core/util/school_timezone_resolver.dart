import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/server_time_service.dart';

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

    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    if (schoolCode.isEmpty) return fallbackTimeZone;

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

    // Preserve a previously resolved non-fallback timezone if network fetch fails.
    if (cachedFor == schoolCode && cachedTz.isNotEmpty) {
      _lastKnownTimeZone = cachedTz;
      ServerTimeService.instance.setSchoolTimeZone(cachedTz);
      return cachedTz;
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
    try {
      final path = ApiPaths.schoolTimezone(code);
      final url = ApiPaths.url(path);
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
        }
      }
    } catch (_) {}
    _lastKnownTimeZone = fallbackTimeZone;
    return fallbackTimeZone;
  }
}
