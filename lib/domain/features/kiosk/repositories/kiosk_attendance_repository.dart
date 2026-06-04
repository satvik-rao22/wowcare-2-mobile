import 'package:wowcare/domain/features/kiosk/entities/kiosk_attendance_entity.dart';

/// Domain repository interface for kiosk attendance operations.
/// Defines contract for data layer implementation.
/// No implementation details or API specifics here.
abstract class KioskAttendanceRepository {
  /// Sign in a staff member via kiosk.
  /// Calls: POST /api/v1/staff-attendance-records/sign-in/self
  /// Then: POST /api/v1/attendance/staff-attendance/sign-in/status
  Future<KioskAttendanceStatusEntity> signInStaff({
    required String staffCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  });

  /// Sign out a staff member via kiosk.
  /// Calls: POST /api/v1/staff-attendance-records/sign-out
  /// Then: POST /api/v1/attendance/staff-attendance/sign-in/status
  Future<KioskAttendanceStatusEntity> signOutStaff({
    required String staffCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  });

  /// Get current sign-in status for staff member(s).
  /// Calls: POST /api/v1/attendance/staff-attendance/sign-in/status
  Future<KioskAttendanceStatusEntity> getStaffAttendanceStatus({
    required List<String> staffCodes,
  });

  /// Sign in student(s) as guardian via kiosk.
  /// Calls: POST /api/v1/student-attendance-records/parent-sign-in
  Future<List<KioskStudentAttendanceEntity>> signInStudents({
    required List<String> studentCodes,
    required String guardianCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  });

  /// Sign out student(s) as guardian via kiosk.
  /// Calls: POST /api/v1/student-attendance-records/parent-sign-out
  Future<List<KioskStudentAttendanceEntity>> signOutStudents({
    required List<String> studentCodes,
    required String guardianCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  });
}
