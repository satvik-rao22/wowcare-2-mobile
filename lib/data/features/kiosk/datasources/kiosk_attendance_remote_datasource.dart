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
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  });

  Future<KioskStaffAttendanceModel> signOutStaff({
    required String staffCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  });

  Future<KioskAttendanceStatusModel> getStaffAttendanceStatus({
    required List<String> staffCodes,
  });

  Future<List<KioskStudentAttendanceModel>> signInStudents({
    required List<String> studentCodes,
    required String guardianCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  });

  Future<List<KioskStudentAttendanceModel>> signOutStudents({
    required List<String> studentCodes,
    required String guardianCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
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
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  }) async {
    try {
      AppLogger.d(
        '[Kiosk] STEP 1: Calling sign-in API: staffCode=$staffCode',
      );

      final payload = {
        'staffCode': staffCode,
        'method': 'GPS',
        'latitude': latitude,
        'longitude': longitude,
        'withinGeofence': withinGeofence,
        'timeZone': timeZone,
        'occurredAt': DateTime.now().toIso8601String(),
        'isExpectedToday': true,
      };

      final response = await _client.post<Map<String, dynamic>>(
        '${ApiConstants.attendanceBaseUrl}/staff-attendance-records/sign-in/self',
        data: payload,
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to sign in: ${response.statusCode}');
      }

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      AppLogger.d('[Kiosk] STEP 1 SUCCESS: API response=$data');

      return KioskStaffAttendanceModel.fromJson(data);
    } catch (e) {
      AppLogger.e('[Kiosk] STEP 1 FAILED: $e');
      rethrow;
    }
  }

  @override
  Future<KioskStaffAttendanceModel> signOutStaff({
    required String staffCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  }) async {
    try {
      AppLogger.d(
        '[Kiosk] STEP 1: Calling sign-out API: staffCode=$staffCode',
      );

      final payload = {
        'staffCode': staffCode,
        'method': 'GPS',
        'latitude': latitude,
        'longitude': longitude,
        'withinGeofence': withinGeofence,
        'timeZone': timeZone,
        'occurredAt': DateTime.now().toIso8601String(),
        'isExpectedToday': true,
      };

      final response = await _client.post<Map<String, dynamic>>(
        '${ApiConstants.attendanceBaseUrl}/staff-attendance-records/sign-out',
        data: payload,
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to sign out: ${response.statusCode}');
      }

      final data = response.data?['data'] as Map<String, dynamic>? ?? {};
      AppLogger.d('[Kiosk] STEP 1 SUCCESS: API response=$data');

      return KioskStaffAttendanceModel.fromJson(data);
    } catch (e) {
      AppLogger.e('[Kiosk] STEP 1 FAILED: $e');
      rethrow;
    }
  }

  @override
  Future<KioskAttendanceStatusModel> getStaffAttendanceStatus({
    required List<String> staffCodes,
  }) async {
    try {
      AppLogger.d(
        '[Kiosk] STEP 2: Calling status API: staffCodes=$staffCodes',
      );

      final payload = {
        'staffCodes': staffCodes,
        'allowedClassroomCodes': <String>[],
      };

      final response = await _client.post<Map<String, dynamic>>(
        '${ApiConstants.attendanceBaseUrl}/staff-attendance/sign-in/status',
        data: payload,
      );

      if (response.statusCode != 200 || response.data == null) {
        throw Exception('Failed to get status: ${response.statusCode}');
      }

      AppLogger.d('[Kiosk] STEP 2 SUCCESS: API response=${response.data}');

      return KioskAttendanceStatusModel.fromJson(response.data!);
    } catch (e) {
      AppLogger.e('[Kiosk] STEP 2 FAILED: $e');
      rethrow;
    }
  }

  @override
  Future<List<KioskStudentAttendanceModel>> signInStudents({
    required List<String> studentCodes,
    required String guardianCode,
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  }) async {
    try {
      AppLogger.d(
        '[Kiosk] Student sign-in: studentCodes=${studentCodes.length}, guardianCode=$guardianCode',
      );

      final payload = {
        'studentCodes': studentCodes,
        'guardianCode': guardianCode,
        'method': 'GPS',
        'latitude': latitude,
        'longitude': longitude,
        'withinGeofence': withinGeofence,
        'timeZone': timeZone,
        'allowedClassroomCodes': <String>[],
      };

      final response = await _client.post<Map<String, dynamic>>(
        '${ApiConstants.attendanceBaseUrl}/student-attendance-records/parent-sign-in',
        data: payload,
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
    required String timeZone,
    required double latitude,
    required double longitude,
    required bool withinGeofence,
  }) async {
    try {
      AppLogger.d(
        '[Kiosk] Student sign-out: studentCodes=${studentCodes.length}, guardianCode=$guardianCode',
      );

      final payload = {
        'studentCodes': studentCodes,
        'guardianCode': guardianCode,
        'method': 'GPS',
        'latitude': latitude,
        'longitude': longitude,
        'withinGeofence': withinGeofence,
        'timeZone': timeZone,
        'allowedClassroomCodes': <String>[],
      };

      final response = await _client.post<Map<String, dynamic>>(
        '${ApiConstants.attendanceBaseUrl}/student-attendance-records/parent-sign-out',
        data: payload,
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
