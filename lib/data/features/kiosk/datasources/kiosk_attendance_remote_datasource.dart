import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/logger_service.dart';
import 'package:wowcare/data/features/kiosk/models/kiosk_attendance_model.dart';

/// Remote data source for kiosk ATTENDANCE operations (refactored Clean Architecture).
/// Handles all API communication for staff/student sign-in/out via kiosk.
/// NOTE: This is separate from KioskRemoteDataSource which handles QR/PIN features.
abstract class KioskAttendanceRemoteDataSource {
  Future<KioskStaffAttendanceModel> signInStaff({
    required String staffCode,
    required String schoolCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
    String? pin,
  });

  Future<KioskStaffAttendanceModel> signOutStaff({
    required String staffCode,
    required String schoolCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
    String? pin,
  });

  Future<List<KioskStudentAttendanceModel>> signInStudents({
    required List<String> studentCodes,
    required String guardianCode,
    required String schoolCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
    String? pin,
  });

  Future<List<KioskStudentAttendanceModel>> signOutStudents({
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

/// Implementation of kiosk attendance remote data source.
/// Uses Dio for HTTP communication with the backend.
class KioskAttendanceRemoteDataSourceImpl implements KioskAttendanceRemoteDataSource {
  KioskAttendanceRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<KioskStaffAttendanceModel> signInStaff({
    required String staffCode,
    required String schoolCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
    String? pin,
  }) async {
    try {
      AppLogger.d(
        '[KIOSK] CallingStaffSignInApi=true, staffCode=$staffCode, Method=KIOSK, PinIncluded=${pin?.isNotEmpty ?? false}',
      );

      final payload = {
        'staffCode': staffCode,
        'method': 'KIOSK',
        if (pin != null) 'pin': pin,
        'latitude': latitude,
        'longitude': longitude,
        'withinGeofence': withinGeofence,
        'timeZone': timeZone,
      };

      final response = await _client.post<Map<String, dynamic>>(
        '${ApiConstants.attendanceBaseUrl}/api/v1/attendance/staff-attendance-records/sign-in',
        data: payload,
        options: Options(headers: {'X-School-Code': schoolCode}),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to sign in: ${response.statusCode}');
      }

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] is List
          ? (responseData['data'] as List).isNotEmpty
              ? (responseData['data'] as List)[0] as Map<String, dynamic>
              : <String, dynamic>{}
          : responseData['data'] as Map<String, dynamic>? ?? {};

      AppLogger.d('[KIOSK] AttendanceSuccess=true, staffCode=$staffCode');

      return KioskStaffAttendanceModel.fromJson(data);
    } catch (e) {
      AppLogger.e('[KIOSK] AttendanceSuccess=false, error=$e');
      rethrow;
    }
  }

  @override
  Future<KioskStaffAttendanceModel> signOutStaff({
    required String staffCode,
    required String schoolCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
    String? pin,
  }) async {
    try {
      AppLogger.d(
        '[KIOSK] CallingStaffSignOutApi=true, staffCode=$staffCode, Method=KIOSK, PinIncluded=${pin?.isNotEmpty ?? false}',
      );

      final payload = {
        'staffCode': staffCode,
        'method': 'KIOSK',
        if (pin != null) 'pin': pin,
        'latitude': latitude,
        'longitude': longitude,
        'withinGeofence': withinGeofence,
        'timeZone': timeZone,
      };

      final response = await _client.post<Map<String, dynamic>>(
        '${ApiConstants.attendanceBaseUrl}/api/v1/attendance/staff-attendance-records/sign-out',
        data: payload,
        options: Options(headers: {'X-School-Code': schoolCode}),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to sign out: ${response.statusCode}');
      }

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] is List
          ? (responseData['data'] as List).isNotEmpty
              ? (responseData['data'] as List)[0] as Map<String, dynamic>
              : <String, dynamic>{}
          : responseData['data'] as Map<String, dynamic>? ?? {};

      AppLogger.d('[KIOSK] AttendanceSuccess=true, staffCode=$staffCode');

      return KioskStaffAttendanceModel.fromJson(data);
    } catch (e) {
      AppLogger.e('[KIOSK] AttendanceSuccess=false, error=$e');
      rethrow;
    }
  }

  @override
  Future<List<KioskStudentAttendanceModel>> signInStudents({
    required List<String> studentCodes,
    required String guardianCode,
    required String schoolCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
    String? pin,
  }) async {
    try {
      AppLogger.d(
        '[KIOSK] Student sign-in: studentCodes=${studentCodes.length}, guardianCode=$guardianCode, method=KIOSK, pinIncluded=${pin?.isNotEmpty ?? false}',
      );

      final payload = {
        'studentCodes': studentCodes,
        'guardianCode': guardianCode,
        'method': 'KIOSK',
        if (pin != null) 'pin': pin,
        'latitude': latitude,
        'longitude': longitude,
        'withinGeofence': withinGeofence,
        'timeZone': timeZone,
      };

      final response = await _client.post<Map<String, dynamic>>(
        '${ApiConstants.attendanceBaseUrl}/api/v1/student-attendance-records/parent-sign-in?guardianCode=$guardianCode',
        data: payload,
        options: Options(headers: {'X-School-Code': schoolCode}),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to sign in students: ${response.statusCode}');
      }

      final data = response.data?['data'] as List<dynamic>? ?? [];
      AppLogger.d('[Kiosk] Student sign-in SUCCESS');

      return data
          .map((item) => KioskStudentAttendanceModel.fromJson(item))
          .toList();
    } catch (e) {
      AppLogger.e('[Kiosk] Student sign-in FAILED: $e');
      rethrow;
    }
  }

  @override
  Future<List<KioskStudentAttendanceModel>> signOutStudents({
    required List<String> studentCodes,
    required String guardianCode,
    required String schoolCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
    String? pin,
  }) async {
    try {
      AppLogger.d(
        '[KIOSK] Student sign-out: studentCodes=${studentCodes.length}, guardianCode=$guardianCode, method=KIOSK, pinIncluded=${pin?.isNotEmpty ?? false}',
      );

      final payload = {
        'studentCodes': studentCodes,
        'guardianCode': guardianCode,
        'method': 'KIOSK',
        if (pin != null) 'pin': pin,
        'latitude': latitude,
        'longitude': longitude,
        'withinGeofence': withinGeofence,
        'timeZone': timeZone,
      };

      final response = await _client.post<Map<String, dynamic>>(
        '${ApiConstants.attendanceBaseUrl}/api/v1/student-attendance-records/parent-sign-out?guardianCode=$guardianCode',
        data: payload,
        options: Options(headers: {'X-School-Code': schoolCode}),
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to sign out students: ${response.statusCode}');
      }

      final data = response.data?['data'] as List<dynamic>? ?? [];
      AppLogger.d('[Kiosk] Student sign-out SUCCESS');

      return data
          .map((item) => KioskStudentAttendanceModel.fromJson(item))
          .toList();
    } catch (e) {
      AppLogger.e('[Kiosk] Student sign-out FAILED: $e');
      rethrow;
    }
  }
}
