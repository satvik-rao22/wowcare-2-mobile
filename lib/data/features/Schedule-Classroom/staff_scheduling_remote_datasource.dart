import 'package:dio/dio.dart';
import '../../../core/util/api_paths.dart';

abstract class StaffSchedulingRemoteDataSource {
  Future<Map<String, dynamic>?> addSchedule(Map<String, dynamic> data);
  Future<void> editSchedule(String id, Map<String, dynamic> data);
  Future<List<Map<String, dynamic>>> getStaffShifts({
    String? classroomCode,
    required String dateFrom,
    required String dateTo,
    String shiftStatus = 'PUBLISHED',
  });
  Future<List<Map<String, dynamic>>> getAllClassrooms(String schoolCode);
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

    await _client.patch<dynamic>(endpoint, data: data);
  }

  @override
  Future<List<Map<String, dynamic>>> getStaffShifts({
    String? classroomCode,
    required String dateFrom,
    required String dateTo,
    String? shiftStatus,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.staffShifts);

    final response = await _client.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: {
        if (classroomCode != null) 'classroomCode': classroomCode,
        if (shiftStatus != null) 'shiftStatus': shiftStatus,
        'dateFrom': dateFrom,
        'dateTo': dateTo,
        'page': 0,
        'size': 100, // Fetching a larger size for the view
      },
    );

    final data = response.data?['data'] as Map<String, dynamic>?;
    final content = data?['content'] as List<dynamic>? ?? [];
    return content.map((e) => e as Map<String, dynamic>).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllClassrooms(String schoolCode) async {
    final endpoint = ApiPaths.url(ApiPaths.classroomAllStatuses);

    final response = await _client.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: {
        'schoolCode': schoolCode,
        'statuses': 'ACTIVE',
      },
    );

    final data = response.data?['data'];
    if (data is List) {
      return data.map((e) => e as Map<String, dynamic>).toList();
    } else if (data is Map<String, dynamic> && data['content'] is List) {
      return (data['content'] as List).map((e) => e as Map<String, dynamic>).toList();
    }
    return [];
  }
}
