import 'package:geolocator/geolocator.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/utils/api_paths.dart';
import '../../../../domain/features/geofencing/entities/attendance_settings_entity.dart';
import '../../../../domain/features/geofencing/entities/geofence_config.dart';
import '../../../../domain/features/geofencing/entities/location_permission_level.dart';
import '../../../../domain/features/geofencing/repositories/geofencing_repository.dart';
import '../datasources/geofencing_local_datasource.dart';
import '../models/attendance_settings_model.dart';
import '../models/school_location_model.dart';

class GeofencingRepositoryImpl implements GeofencingRepository {
  GeofencingRepositoryImpl({
    required GeofencingLocalDataSource localDataSource,
    required ApiClient apiClient,
  })  : _local = localDataSource,
        _apiClient = apiClient;

  final GeofencingLocalDataSource _local;
  final ApiClient _apiClient;

  @override
  Future<LocationPermissionLevel> getPermissionLevel() =>
      _local.getPermissionLevel();

  @override
  Future<LocationPermissionLevel> requestLocationPermission() =>
      _local.requestLocationPermission();

  @override
  Future<bool> isLocationServiceEnabled() => _local.isLocationServiceEnabled();

  /// Fetches school lat/lon from the timezone endpoint and attendance settings
  /// (GPS toggle + radius) from the attendance-settings endpoint, then merges
  /// them into a single [GeofenceConfig].
  ///
  /// Both calls run in parallel. If the attendance-settings call fails (e.g.
  /// endpoint not yet live on this environment) we fall back to safe defaults
  /// so the rest of the app keeps working.
  @override
  Future<GeofenceConfig> getSchoolLocation({required String schoolCode}) async {
    // Run both in parallel; attendance-settings failure is non-fatal.
    final locationFuture = _fetchSchoolLocation(schoolCode);
    final settingsFuture = getAttendanceSettings(schoolCode: schoolCode)
        .catchError((Object _) => AttendanceSettingsEntity(
              gpsSignInEnabled: true,
              parentGpsSignInEnabled: true,
              proximityRadiusMeters: 500,
              maxProximityLimitMeters: 500,
              allowOutsideSchoolHours: true,
              outsideTimeWindowMinutes: 0,
              allowTeacherCrossClassAttendance: false,
              autoSignOutEnabled: false,
              autoSignOutDelayMinutes: 0,
            ));

    final locationModel = await locationFuture;
    final settings = await settingsFuture;

    return GeofenceConfig(
      schoolCode: locationModel.schoolCode.isNotEmpty
          ? locationModel.schoolCode
          : schoolCode,
      latitude: locationModel.latitude,
      longitude: locationModel.longitude,
      radiusMeters: settings.proximityRadiusMeters,
      gpsSignInEnabled: settings.gpsSignInEnabled,
      parentGpsSignInEnabled: settings.parentGpsSignInEnabled,
      autoSignOutEnabled: settings.autoSignOutEnabled,
      autoSignOutDelayMinutes: settings.autoSignOutDelayMinutes,
    );
  }

  @override
  Future<AttendanceSettingsEntity> getAttendanceSettings({
    required String schoolCode,
  }) async {
    final path = ApiPaths.attendanceSettings(schoolCode);
    final url = ApiPaths.url(path);
    final response = await _apiClient.client.get<dynamic>(url);
    final model = AttendanceSettingsModel.fromJson(
      response.data as Map<String, dynamic>? ?? {},
    );
    return model.toEntity();
  }

  Future<SchoolLocationModel> _fetchSchoolLocation(String schoolCode) async {
    final path = ApiPaths.schoolTimezone(schoolCode);
    final url = ApiPaths.url(path);
    final response = await _apiClient.client.get<dynamic>(url);
    return SchoolLocationModel.fromJson(
      response.data as Map<String, dynamic>? ?? {},
    );
  }

  @override
  Future<Position> getCurrentPosition() => _local.getCurrentPosition();

  @override
  Stream<Position> getPositionStream() => _local.getPositionStream();
}
