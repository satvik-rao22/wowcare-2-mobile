import 'package:dio/dio.dart';
import '../../../core/util/api_paths.dart';

abstract class StaffSchedulingRemoteDataSource {
  Future<Map<String, dynamic>?> addSchedule(Map<String, dynamic> data);
  Future<void> editSchedule(String id, Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getStaffShifts({
    required String classroomCode,
    required String dateFrom,
    required String dateTo,
    String shiftStatus = 'PUBLISHED',
  });
}

class StaffSchedulingRemoteDataSourceImpl
    implements StaffSchedulingRemoteDataSource {
  final Dio _client;

  StaffSchedulingRemoteDataSourceImpl(this._client);

  @override
  Future<Map<String, dynamic>?> addSchedule(Map<String, dynamic> data) async {
    final endpoint = ApiPaths.url(ApiPaths.staffShifts);

    final response = await _client.post<Map<String, dynamic>>(
      endpoint,
      data: data,
    );
    return response.data?['data'] as Map<String, dynamic>?;
  }

  @override
  Future<void> editSchedule(String id, Map<String, dynamic> data) async {
    final endpoint = ApiPaths.url('${ApiPaths.staffShifts}/$id');

    await _client.patch<dynamic>(
      endpoint,
      data: data,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getStaffShifts({
    required String classroomCode,
    required String dateFrom,
    required String dateTo,
    String shiftStatus = 'PUBLISHED',
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.staffShifts);

    final response = await _client.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: {
        'classroomCode': classroomCode,
        'shiftStatus': shiftStatus,
        'dateFrom': dateFrom,
        'dateTo': dateTo,
        'page': 0,
        'size': 100, // Fetching a larger size for the view
      },
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    final content = data?['content'] as List<dynamic>? ?? [];
    return content.cast<Map<String, dynamic>>();
  }
}
