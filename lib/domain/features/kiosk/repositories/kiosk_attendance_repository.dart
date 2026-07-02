import 'package:wowcare/domain/features/kiosk/entities/kiosk_attendance_entity.dart';

/// Domain repository interface for kiosk attendance operations.
/// Defines contract for data layer implementation.
/// No implementation details or API specifics here.
abstract class KioskAttendanceRepository {
  /// Sign in a staff member via kiosk.
  /// Calls ONLY: POST /api/v1/attendance/staff-attendance-records/sign-in
  /// Returns staffCode and attendance status from sign-in response directly.
  /// Does NOT call dashboard APIs (staff lookup, form listing, status checks).
  Future<KioskStaffAttendanceEntity> signInStaff({
    required String staffCode,
    required String schoolCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
    String? pin,
  });

  /// Sign out a staff member via kiosk.
  /// Calls ONLY: POST /api/v1/attendance/staff-attendance-records/sign-out
  /// Does NOT call dashboard attendance APIs.
  Future<KioskStaffAttendanceEntity> signOutStaff({
    required String staffCode,
    required String schoolCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
    String? pin,
  });

  /// Sign in student(s) as guardian via kiosk.
  /// Calls: POST /api/v1/attendance/student-attendance-records/sign-in
  Future<List<KioskStudentAttendanceEntity>> signInStudents({
    required List<String> studentCodes,
    required String guardianCode,
    required String schoolCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
    String? pin,
  });

  /// Sign out student(s) as guardian via kiosk.
  /// Calls: POST /api/v1/attendance/student-attendance-records/sign-out
  Future<List<KioskStudentAttendanceEntity>> signOutStudents({
    required List<String> studentCodes,
    required String guardianCode,
    required String schoolCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
    String? pin,
  });
}
