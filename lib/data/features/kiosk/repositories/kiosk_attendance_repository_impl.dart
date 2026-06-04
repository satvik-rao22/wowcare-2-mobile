import 'package:wowcare/data/features/kiosk/datasources/kiosk_attendance_remote_datasource.dart';
import 'package:wowcare/domain/features/kiosk/entities/kiosk_attendance_entity.dart';
import 'package:wowcare/domain/features/kiosk/repositories/kiosk_attendance_repository.dart';

/// Implementation of kiosk attendance repository.
/// Bridges domain layer (business logic) with data layer (API calls).
/// Converts models to entities for domain layer consumption.
class KioskAttendanceRepositoryImpl implements KioskAttendanceRepository {
  KioskAttendanceRepositoryImpl(this._remoteDataSource);

  final KioskAttendanceRemoteDataSource _remoteDataSource;

  @override
  Future<KioskStaffAttendanceEntity> signInStaff({
    required String staffCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  }) async {
    // Call sign-in API directly with verified kiosk staffCode
    // Do NOT call dashboard attendance APIs (staff lookup, form listing, status checks)
    final model = await _remoteDataSource.signInStaff(
      staffCode: staffCode,
      timeZone: timeZone,
      latitude: latitude,
      longitude: longitude,
      withinGeofence: withinGeofence,
    );

    // Convert model to entity and return
    // No additional API calls needed
    return model.toEntity();
  }

  @override
  Future<KioskStaffAttendanceEntity> signOutStaff({
    required String staffCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  }) async {
    // Call sign-out API directly with verified kiosk staffCode
    // Do NOT call dashboard attendance APIs
    final model = await _remoteDataSource.signOutStaff(
      staffCode: staffCode,
      timeZone: timeZone,
      latitude: latitude,
      longitude: longitude,
      withinGeofence: withinGeofence,
    );

    // Convert model to entity and return
    // No additional API calls needed
    return model.toEntity();
  }

  @override
  Future<KioskAttendanceStatusEntity> getStaffAttendanceStatus({
    required List<String> staffCodes,
  }) async {
    final model = await _remoteDataSource.getStaffAttendanceStatus(
      staffCodes: staffCodes,
    );
    return model.toEntity();
  }

  @override
  Future<List<KioskStudentAttendanceEntity>> signInStudents({
    required List<String> studentCodes,
    required String guardianCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  }) async {
    final models = await _remoteDataSource.signInStudents(
      studentCodes: studentCodes,
      guardianCode: guardianCode,
      timeZone: timeZone,
      latitude: latitude,
      longitude: longitude,
      withinGeofence: withinGeofence,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<KioskStudentAttendanceEntity>> signOutStudents({
    required List<String> studentCodes,
    required String guardianCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  }) async {
    final models = await _remoteDataSource.signOutStudents(
      studentCodes: studentCodes,
      guardianCode: guardianCode,
      timeZone: timeZone,
      latitude: latitude,
      longitude: longitude,
      withinGeofence: withinGeofence,
    );
    return models.map((m) => m.toEntity()).toList();
  }
}
