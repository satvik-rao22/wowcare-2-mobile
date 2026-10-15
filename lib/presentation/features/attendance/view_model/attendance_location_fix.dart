import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/location_service.dart';

/// Takes the GPS fix an attendance sign-in or sign-out sends with its request.
///
/// The four submit forms (student and staff, sign-in and sign-out) take the
/// same fix through [LocationService]. They go through here so every attempt
/// is logged once as [AppEvent.attendanceLocationCheck].
///
/// Never throws. [LocationService] falls back to the last known position,
/// then to none, and the submit goes ahead either way. Succeeded means the
/// submit carries a position (a last-known one counts); failed means it fell
/// back to none. [LocationService] swallows the reason, so a failure is always
/// [EventFailure.unavailable]. The event never carries the position, a
/// distance or the geofence result.
class AttendanceLocationFix {
  const AttendanceLocationFix({
    Future<LocationPoint?> Function() location = _auditFix,
  }) : _location = location;

  final Future<LocationPoint?> Function() _location;

  Future<LocationPoint?> take() async {
    final stopwatch = Stopwatch()..start();
    final location = await _location();

    final durationMs = stopwatch.elapsedMilliseconds;
    if (location != null) {
      AppEvents.succeeded(
        AppEvent.attendanceLocationCheck,
        durationMs: durationMs,
      );
    } else {
      AppEvents.failed(
        AppEvent.attendanceLocationCheck,
        EventFailure.unavailable,
        durationMs: durationMs,
      );
    }
    return location;
  }

  /// Recorded on the attendance record for audit; it doesn't gate it.
  static Future<LocationPoint?> _auditFix() =>
      LocationService.getCurrentLocation(
        timeLimit: const Duration(seconds: 10),
        fallbackToLastKnown: true,
      );
}
