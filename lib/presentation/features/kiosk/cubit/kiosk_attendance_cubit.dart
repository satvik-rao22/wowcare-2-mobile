import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/core/util/school_zone_datetime.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/core/util/school_timezone_resolver.dart';

part 'kiosk_attendance_state.dart';

/// Cubit for handling kiosk user sign-in/sign-out (both staff and students).
///
/// For KIOSK USERS ONLY:
/// - Staff: Uses ONLY `/api/v1/staff-attendance-records/sign-in/self`
/// - Students: Uses ONLY `/api/v1/student-attendance-records/parent-sign-in`
class KioskAttendanceCubit extends Cubit<KioskAttendanceState> {
  KioskAttendanceCubit({
    required AttendanceRepository attendanceRepository,
    required StorageService storageService,
    required ApiClient apiClient,
  })  : _attendanceRepository = attendanceRepository,
        _storage = storageService,
        _apiClient = apiClient,
        super(const KioskAttendanceInitial());

  final AttendanceRepository _attendanceRepository;
  final StorageService _storage;
  final ApiClient _apiClient;

  /// Sign in staff member (KIOSK ONLY).
  /// Uses: POST /api/v1/staff-attendance-records/sign-in/self
  Future<void> signInStaff({
    required String staffCode,
    double latitude = 0,
    double longitude = 0,
    bool withinGeofence = true,
  }) async {
    emit(const KioskAttendanceSubmitting());

    try {
      // Get school timezone
      final schoolTimeZone =
          await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storage,
        apiClient: _apiClient,
      );

      // Get current time in school timezone
      final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
        DateTime.now().toUtc(),
        schoolTimeZone,
      );

      // Build payload for staff sign-in
      final payload = <String, dynamic>{
        'staffCode': staffCode,
        'method': 'GPS',
        'latitude': latitude,
        'longitude': longitude,
        'withinGeofence': withinGeofence,
        'timeZone': schoolTimeZone,
        'occurredAt': now.toIso8601String(),
        'isExpectedToday': false,
      };

      AppLogger.d(
        '[KioskAttendance] Staff sign-in initiated: '
        'staffCode=$staffCode, endpoint=/staff-attendance-records/sign-in/self, '
        'timezone=$schoolTimeZone, occurredAt=${now.toIso8601String()}',
      );

      // Submit staff sign-in (isSelf=true)
      final result = await _attendanceRepository.submitStaffSignIn(
        payload: payload,
        isSelf: true, // CRITICAL: Use self endpoint for kiosk
      );

      AppLogger.d(
        '[KioskAttendance] Staff sign-in SUCCESS: '
        'staffCode=$staffCode, message=${result.message}',
      );

      emit(KioskAttendanceSuccess(
        message: result.message ?? 'Signed in successfully',
        action: 'SIGN_IN',
        role: 'STAFF',
      ));
    } catch (e) {
      AppLogger.e('[KioskAttendance] Staff sign-in FAILED: staffCode=$staffCode, error=$e');
      emit(KioskAttendanceError('Failed to sign in: $e'));
    }
  }

  /// Sign out staff member (KIOSK ONLY).
  /// Uses: POST /api/v1/staff-attendance-records/sign-out
  Future<void> signOutStaff({
    required String staffCode,
    double latitude = 0,
    double longitude = 0,
    bool withinGeofence = true,
  }) async {
    emit(const KioskAttendanceSubmitting());

    try {
      // Get school timezone
      final schoolTimeZone =
          await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storage,
        apiClient: _apiClient,
      );

      // Get current time in school timezone
      final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
        DateTime.now().toUtc(),
        schoolTimeZone,
      );

      // Build payload for staff sign-out
      final payload = <String, dynamic>{
        'staffCode': staffCode,
        'method': 'GPS',
        'latitude': latitude,
        'longitude': longitude,
        'withinGeofence': withinGeofence,
        'timeZone': schoolTimeZone,
        'occurredAt': now.toIso8601String(),
        'isExpectedToday': false,
      };

      AppLogger.d(
        '[KioskAttendance] Staff sign-out initiated: '
        'staffCode=$staffCode, endpoint=/staff-attendance-records/sign-out, '
        'timezone=$schoolTimeZone, occurredAt=${now.toIso8601String()}',
      );

      // Submit staff sign-out
      final result = await _attendanceRepository.submitStaffSignOut(
        payload: payload,
      );

      AppLogger.d(
        '[KioskAttendance] Staff sign-out SUCCESS: '
        'staffCode=$staffCode, message=${result.message}',
      );

      emit(KioskAttendanceSuccess(
        message: result.message ?? 'Signed out successfully',
        action: 'SIGN_OUT',
        role: 'STAFF',
      ));
    } catch (e) {
      AppLogger.e('[KioskAttendance] Staff sign-out FAILED: staffCode=$staffCode, error=$e');
      emit(KioskAttendanceError('Failed to sign out: $e'));
    }
  }

  /// Sign in student(s) as guardian (KIOSK ONLY).
  /// Uses: POST /api/v1/student-attendance-records/parent-sign-in
  Future<void> signInStudents({
    required List<String> studentCodes,
    required String guardianCode,
    double latitude = 0,
    double longitude = 0,
    bool withinGeofence = true,
  }) async {
    emit(const KioskAttendanceSubmitting());

    try {
      // Get school timezone
      final schoolTimeZone =
          await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storage,
        apiClient: _apiClient,
      );

      // Get current time in school timezone
      final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
        DateTime.now().toUtc(),
        schoolTimeZone,
      );

      // Build payload for student parent sign-in
      final payload = <String, dynamic>{
        'studentCodes': studentCodes,
        'method': 'GPS',
        'latitude': latitude,
        'longitude': longitude,
        'withinGeofence': withinGeofence,
        'timeZone': schoolTimeZone,
        'guardianCode': guardianCode,
        'allowedClassroomCodes': <String>[],
      };

      AppLogger.d(
        '[KioskAttendance] Student sign-in initiated: '
        'studentCodes=${studentCodes.length}, '
        'endpoint=/student-attendance-records/parent-sign-in, '
        'guardianCode=$guardianCode, timezone=$schoolTimeZone, '
        'occurredAt=${now.toIso8601String()}',
      );

      // Submit student sign-in (isParent=true for guardian)
      final result = await _attendanceRepository.submitStudentSignIn(
        payload: payload,
        isParent: true, // CRITICAL: Use parent endpoint for kiosk guardian
      );

      AppLogger.d(
        '[KioskAttendance] Student sign-in SUCCESS: '
        'studentCount=${studentCodes.length}, message=${result.message}',
      );

      emit(KioskAttendanceSuccess(
        message: result.message ?? 'Signed in successfully',
        action: 'SIGN_IN',
        role: 'GUARDIAN',
      ));
    } catch (e) {
      AppLogger.e(
        '[KioskAttendance] Student sign-in FAILED: '
        'studentCount=${studentCodes.length}, error=$e',
      );
      emit(KioskAttendanceError('Failed to sign in: $e'));
    }
  }

  /// Sign out student(s) as guardian (KIOSK ONLY).
  /// Uses: POST /api/v1/student-attendance-records/parent-sign-out
  Future<void> signOutStudents({
    required List<String> studentCodes,
    required String guardianCode,
    double latitude = 0,
    double longitude = 0,
    bool withinGeofence = true,
  }) async {
    emit(const KioskAttendanceSubmitting());

    try {
      // Get school timezone
      final schoolTimeZone =
          await SchoolTimezoneResolver.resolveForCurrentSchool(
        storage: _storage,
        apiClient: _apiClient,
      );

      // Get current time in school timezone
      final now = SchoolZoneDateTime.dateTimeFromInstantInSchool(
        DateTime.now().toUtc(),
        schoolTimeZone,
      );

      // Build payload for student parent sign-out
      final payload = <String, dynamic>{
        'studentCodes': studentCodes,
        'method': 'GPS',
        'latitude': latitude,
        'longitude': longitude,
        'withinGeofence': withinGeofence,
        'timeZone': schoolTimeZone,
        'guardianCode': guardianCode,
        'allowedClassroomCodes': <String>[],
      };

      AppLogger.d(
        '[KioskAttendance] Student sign-out initiated: '
        'studentCodes=${studentCodes.length}, '
        'endpoint=/student-attendance-records/parent-sign-out, '
        'guardianCode=$guardianCode, timezone=$schoolTimeZone',
      );

      // Submit student sign-out (isParent=true for guardian)
      final result = await _attendanceRepository.submitStudentSignOut(
        payload: payload,
        isParent: true, // CRITICAL: Use parent endpoint for kiosk guardian
      );

      AppLogger.d(
        '[KioskAttendance] Student sign-out SUCCESS: '
        'studentCount=${studentCodes.length}, message=${result.message}',
      );

      emit(KioskAttendanceSuccess(
        message: result.message ?? 'Signed out successfully',
        action: 'SIGN_OUT',
        role: 'GUARDIAN',
      ));
    } catch (e) {
      AppLogger.e(
        '[KioskAttendance] Student sign-out FAILED: '
        'studentCount=${studentCodes.length}, error=$e',
      );
      emit(KioskAttendanceError('Failed to sign out: $e'));
    }
  }

  /// Reset to initial state
  void reset() {
    emit(const KioskAttendanceInitial());
  }
}
