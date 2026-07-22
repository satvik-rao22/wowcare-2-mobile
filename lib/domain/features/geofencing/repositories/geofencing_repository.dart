import 'package:geolocator/geolocator.dart';
import '../entities/attendance_settings_entity.dart';
import '../entities/geofence_config.dart';
import '../entities/location_permission_level.dart';

abstract class GeofencingRepository {
  /// Reads the current permission level without prompting the OS dialog.
  Future<LocationPermissionLevel> getPermissionLevel();

  /// Requests foreground ("While Using the App") location permission only —
  /// never escalates to background/"Always" automatically.
  Future<LocationPermissionLevel> requestLocationPermission();
  Future<bool> isLocationServiceEnabled();

  /// Returns school lat/lon combined with attendance-settings radius + flags.
  Future<GeofenceConfig> getSchoolLocation({required String schoolCode});

  /// Fetches raw attendance settings — exposed so callers can inspect all
  /// fields (e.g. autoSignOut) without going through [getSchoolLocation].
  Future<AttendanceSettingsEntity> getAttendanceSettings({
    required String schoolCode,
  });

  Future<Position> getCurrentPosition();
  Stream<Position> getPositionStream();
}
