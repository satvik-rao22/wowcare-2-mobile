import 'package:geolocator/geolocator.dart';
import 'package:wowcare/core/observability/app_events.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// Takes the GPS fix an attendance sign-in or sign-out sends with its request.
///
/// The four submit forms (student and staff, sign-in and sign-out) used to
/// take this fix with the same code each. It lives here so every attempt is
/// logged once as [AppEvent.attendanceLocationCheck], bucketed the same way.
///
/// Never throws. A failed fix falls back to the last known position, then to
/// none, and the submit goes ahead either way. Succeeded means the submit
/// carries a position (a last-known one counts); failed means it fell back to
/// none. The event never carries the position, a distance or the geofence
/// result.
class AttendanceLocationFix {
  const AttendanceLocationFix({
    Future<Position> Function() currentPosition = _highAccuracyFix,
    Future<Position?> Function() lastKnownPosition =
        Geolocator.getLastKnownPosition,
  }) : _currentPosition = currentPosition,
       _lastKnownPosition = lastKnownPosition;

  final Future<Position> Function() _currentPosition;
  final Future<Position?> Function() _lastKnownPosition;

  /// [caller] only names the form in the debug log, as before.
  Future<Position?> take({required String caller}) async {
    final stopwatch = Stopwatch()..start();
    Object? fixError;
    Position? position;
    try {
      position = await _currentPosition();
    } catch (error) {
      fixError = error;
      try {
        position = await _lastKnownPosition();
      } catch (e) {
        AppLogger.d('$caller: getLastKnownPosition failed: $e');
      }
    }

    final durationMs = stopwatch.elapsedMilliseconds;
    if (position != null) {
      AppEvents.succeeded(
        AppEvent.attendanceLocationCheck,
        durationMs: durationMs,
      );
    } else {
      AppEvents.failed(
        AppEvent.attendanceLocationCheck,
        failureOf(fixError),
        durationMs: durationMs,
      );
    }
    return position;
  }

  /// The bucket for the error that cost the submit its fix. A timeout (the
  /// 10 s `timeLimit`) is a `TimeoutException`, bucketed by [EventFailure.of].
  static EventFailure failureOf(Object? error) {
    return switch (error) {
      PermissionDeniedException() => EventFailure.permission,
      LocationServiceDisabledException() || null => EventFailure.unavailable,
      _ => EventFailure.of(error),
    };
  }

  static Future<Position> _highAccuracyFix() => Geolocator.getCurrentPosition(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      timeLimit: Duration(seconds: 10),
    ),
  );
}
