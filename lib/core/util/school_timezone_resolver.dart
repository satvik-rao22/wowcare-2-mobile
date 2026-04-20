import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/api_paths.dart';
import 'package:wowcare/core/util/storage_keys.dart';

/// Loads the school's IANA timezone from the backend for use in attendance payloads.
///
/// Timestamps should remain UTC ([DateTime.toUtc] / `...Z` ISO strings). The
/// [timeZone] field tells the server which school zone applies for interpretation.
abstract final class SchoolTimezoneResolver {
  SchoolTimezoneResolver._();

  static const String fallbackTimeZone = 'UTC';

  static Future<String> resolveForCurrentSchool({
    required StorageService storage,
    required ApiClient apiClient,
  }) async {
    final schoolCode = (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    if (schoolCode.isEmpty) return fallbackTimeZone;

    final cachedFor =
        (await storage.getString(StorageKeys.schoolTimeZoneSchoolCode) ?? '').trim();
    final cachedTz = (await storage.getString(StorageKeys.schoolTimeZone) ?? '').trim();
    if (cachedFor == schoolCode && cachedTz.isNotEmpty) {
      return cachedTz;
    }

    final tz = await fetchSchoolTimeZone(
      schoolCode: schoolCode,
      apiClient: apiClient,
    );
    await storage.saveString(StorageKeys.schoolTimeZoneSchoolCode, schoolCode);
    await storage.saveString(StorageKeys.schoolTimeZone, tz);
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
          if (raw.isNotEmpty) return raw;
        }
      }
    } catch (_) {}
    return fallbackTimeZone;
  }
}
