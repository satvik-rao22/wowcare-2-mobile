import 'package:geolocator/geolocator.dart';
import '../entities/attendance_settings_entity.dart';
import '../entities/geofence_config.dart';

abstract class GeofencingRepository {
  Future<bool> hasLocationPermission();
  Future<bool> requestLocationPermission();
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
