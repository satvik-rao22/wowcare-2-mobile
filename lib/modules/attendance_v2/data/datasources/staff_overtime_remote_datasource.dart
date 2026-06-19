import 'package:dio/dio.dart';
import 'package:wowcare/core/util/api_constants.dart';
import 'package:wowcare/core/util/api_paths.dart';

/// Calls the overview endpoint using the host app's Dio client (so the auth +
/// org/school header interceptors apply automatically). `staffCode` goes in the
/// body; org/school/auth are added by the interceptor.
class StaffOvertimeRemoteDataSource {
  StaffOvertimeRemoteDataSource(this._client);

  final Dio _client;

  static const String _overviewPath = '/api/v1/staff-overtime-records/profile';

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
