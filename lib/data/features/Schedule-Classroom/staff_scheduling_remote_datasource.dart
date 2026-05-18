import 'package:dio/dio.dart';

import '../../../core/util/api_paths.dart';

abstract class StaffSchedulingRemoteDataSource {
  Future<Map<String, dynamic>?> addSchedule(Map<String, dynamic> data);

  Future<void> editSchedule(String id, Map<String, dynamic> data);

  Future<List<Map<String, dynamic>>> getStaffShifts({
    required String schoolCode,
    required String organizationCode,
    String? classroomCode,
    required String dateFrom,
    required String dateTo,
    String? shiftStatus,
    int page = 0,
    int size = 50,
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

    await _client.patch(endpoint, data: data);
  }

  @override
  Future<List<Map<String, dynamic>>> getStaffShifts({
    required String schoolCode,
    required String organizationCode,
    String? classroomCode,
    required String dateFrom,
    required String dateTo,
    String? shiftStatus,
    int page = 0,
    int size = 50,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.staffShifts);

    final response = await _client.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: {
        'schoolCode': schoolCode,
        'organizationCode': organizationCode,
        'dateFrom': dateFrom,
        'dateTo': dateTo,
        'page': page,
        'size': size,

        if (classroomCode != null && classroomCode.isNotEmpty)
          'classroomCode': classroomCode,

        if (shiftStatus != null && shiftStatus.isNotEmpty)
          'shiftStatus': shiftStatus,
      },
    );

    final responseData = response.data;

    if (responseData == null) {
      return [];
    }

    final data = responseData['data'];

    if (data == null) {
      return [];
    }

    final content = data['content'];

    if (content is! List) {
      return [];
    }

    return content.map((e) => Map<String, dynamic>.from(e)).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> getAllClassrooms(String schoolCode) async {
    final endpoint = ApiPaths.url(ApiPaths.classroomAllStatuses);

    final response = await _client.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: {'schoolCode': schoolCode, 'statuses': 'ACTIVE'},
    );

    final responseData = response.data;

    if (responseData == null) {
      return [];
    }

    final data = responseData['data'];

    // Case 1:
    // {
    //   "data": []
    // }
    if (data is List) {
      return data.map((e) => Map<String, dynamic>.from(e)).toList();
    }

    // Case 2:
    // {
    //   "data": {
    //      "content": []
    //   }
    // }
    if (data is Map<String, dynamic>) {
      final content = data['content'];

      if (content is List) {
        return content.map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }

    return [];
  }
}
