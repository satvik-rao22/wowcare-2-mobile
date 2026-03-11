import 'package:dio/dio.dart';

import '../../../../core/util/api_paths.dart';
import '../models/student_classroom_models.dart';

abstract class StudentClassroomRemoteDataSource {
  /// Calls `GET /api/v1/student-classroom` with the given filters.
  Future<List<StudentClassroomItemModel>> getStudentClassroomList({
    required String schoolCode,
    required String classroomCode,
    List<String>? tagCodes,
    List<String>? status,
    String? attendanceStatus,
  });
}

class StudentClassroomRemoteDataSourceImpl
    implements StudentClassroomRemoteDataSource {
  StudentClassroomRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<List<StudentClassroomItemModel>> getStudentClassroomList({
    required String schoolCode,
    required String classroomCode,
    List<String>? tagCodes,
    List<String>? status,
    String? attendanceStatus,
  }) async {
    final endpoint = ApiPaths.url(ApiPaths.studentClassroom);

    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      'classroomCode': classroomCode,
    };

    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (attendanceStatus != null && attendanceStatus.isNotEmpty) {
      queryParameters['attendanceStatus'] = attendanceStatus;
    }
    if (tagCodes != null && tagCodes.isNotEmpty) {
      queryParameters['tagCodes'] = tagCodes;
    }

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected student-classroom API response format');
    }

    final List<dynamic> data = body['data'] as List<dynamic>? ?? const [];

    return data
        .whereType<Map<String, dynamic>>()
        .map(StudentClassroomItemModel.fromJson)
        .toList();
  }
}


