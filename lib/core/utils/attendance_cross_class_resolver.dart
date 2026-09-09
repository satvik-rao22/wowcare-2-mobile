import 'package:wowcare/app/di/di.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import 'package:wowcare/core/utils/storage_keys.dart';

/// Resolves the per-school `allowTeacherCrossClassAttendance` flag from
/// GET /api/v1/attendance/schools/{schoolCode}/attendance-settings/allow-teacher-cross-class-attendance
///
/// When the flag is true, a non-admin staff member (teacher) is treated as
/// UNSCOPED for STUDENT attendance — they can view and act on students from any
/// classroom, exactly like an admin. When false (or unknown), the existing
/// classroom scoping is preserved.
///
/// The result is memoized per school for the session (with in-flight de-dupe)
/// so the many attendance API calls don't each trigger a network round-trip.
/// Only successful reads are cached — a transient failure defaults to `false`
/// (safe: keeps current scoping) without being remembered, so the next call
/// retries.
abstract final class AttendanceCrossClassResolver {
  static final Map<String, bool> _cacheBySchool = <String, bool>{};
  static final Map<String, Future<bool?>> _inFlightBySchool =
      <String, Future<bool?>>{};

  /// Last resolved value for the active school, for synchronous readers (e.g.
  /// the attendance permission gate, which can't await). Defaults to false and
  /// is updated every time [isEnabledForCurrentSchool] resolves. Callers that
  /// depend on this should trigger [isEnabledForCurrentSchool] first (e.g. when
  /// the attendance popup/screen opens) so it reflects the current school.
  static bool _lastKnownEnabled = false;
  static bool get lastKnownEnabled => _lastKnownEnabled;

  /// Clears memoized values — call on logout / active-school switch.
  static void reset() {
    _cacheBySchool.clear();
    _inFlightBySchool.clear();
    _lastKnownEnabled = false;
  }

  /// True when teachers may act on students from any classroom at the active
  /// school. Defaults to false when no school is selected or the flag can't be
  /// resolved.
  static Future<bool> isEnabledForCurrentSchool({
    required StorageService storage,
  }) async {
    final schoolCode =
        (await storage.getString(StorageKeys.schoolCode) ?? '').trim();
    if (schoolCode.isEmpty) return false;

    final cached = _cacheBySchool[schoolCode];
    if (cached != null) {
      _lastKnownEnabled = cached;
      return cached;
    }

    final inFlight = _inFlightBySchool[schoolCode];
    if (inFlight != null) {
      final v = (await inFlight) ?? false;
      _lastKnownEnabled = v;
      return v;
    }

    final future = _fetch(schoolCode);
    _inFlightBySchool[schoolCode] = future;
    try {
      final value = await future;
      if (value != null) {
        _cacheBySchool[schoolCode] = value;
        _lastKnownEnabled = value;
      }
      return value ?? false;
    } finally {
      _inFlightBySchool.remove(schoolCode);
    }
  }

  /// Returns the flag, or null when it could not be determined (so callers
  /// don't cache a fallback).
  static Future<bool?> _fetch(String schoolCode) async {
    try {
      final apiClient = serviceLocator<ApiClient>();
      final path = ApiPaths.allowTeacherCrossClassAttendance(schoolCode);
      final url = ApiPaths.url(path);
      final response = await apiClient.client.get<dynamic>(url);
      final root = response.data;
      if (root is Map<String, dynamic>) {
        final data = root['data'];
        if (data is Map<String, dynamic>) {
          final value = data['allowTeacherCrossClassAttendance'];
          if (value is bool) return value;
        }
      }
    } catch (_) {
      // Network/parse failure — leave unresolved so the caller retries later.
    }
    return null;
  }
}
