import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';

/// Calls the overtime endpoints using the host app's Dio client (so the auth +
/// org/school header interceptors apply automatically).
///
/// Two steps: [calculate] recomputes overtime into the backend table, then
/// [getOverview] reads the calculated result.
class StaffOvertimeRemoteDataSource {
  StaffOvertimeRemoteDataSource(this._client);

  final Dio _client;

  static const String _overviewPath = '/api/v1/staff-overtime-records/profile';
  static const String _calculatePath =
      '/api/v1/staff-overtime-records/calculate';

  /// Triggers a server-side recompute for the range. Note: `staffCode` is sent
  /// as an array here (the calculate endpoint accepts a batch).
  Future<void> calculate({
    required String staffCode,
    required String fromDate,
    required String toDate,
  }) async {
    final endpoint =
        ApiPaths.urlWithBase(_calculatePath, ApiConstants.attendanceBaseUrl);
    await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'staffCode': <String>[staffCode],
        'fromDate': fromDate,
        'toDate': toDate,
      },
    );
  }

  /// Edits a single attendance (sign-in/out) record. [body] already contains
  /// the UTC `signedInAt`/`signedOutAt`, methods and `timeZone`.
  Future<void> editDailyRecord({
    required String recordCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceDailyRecordByRowCode(recordCode),
      ApiConstants.attendanceBaseUrl,
    );
    await _client.patch<dynamic>(endpoint, data: body);
  }

  /// Reads the calculated per-day overview.
  Future<Map<String, dynamic>?> getOverview({
    required String staffCode,
    required String fromDate,
    required String toDate,
  }) async {
    final endpoint =
        ApiPaths.urlWithBase(_overviewPath, ApiConstants.attendanceBaseUrl);
    final response = await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'staffCode': staffCode,
        'fromDate': fromDate,
        'toDate': toDate,
      },
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }
}
