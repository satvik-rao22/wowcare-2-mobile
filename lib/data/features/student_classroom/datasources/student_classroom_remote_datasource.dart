import 'package:dio/dio.dart';

import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/student_classroom_models.dart';

abstract class StudentClassroomRemoteDataSource {
  /// Calls `GET /api/v1/student-classroom` with the given filters.
  Future<List<StudentClassroomItemModel>> getStudentClassroomList({
    required String schoolCode,
    required String classroomCode,
    String? firstName,
    String? lastName,
    String? search,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? status,
    String? attendanceStatus,
  });

  /// Calls `POST /api/v1/student-classroom/assign-student`.
  ///
  /// Backend expects `studentCode` as array in query params.
  Future<StudentClassroomAssignResponseModel> assignStudentsToClassroom({
    required String classroomCode,
    required List<String> studentCodes,
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
    String? firstName,
    String? lastName,
    String? search,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? status,
    String? attendanceStatus,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentClassroom,
      ApiConstants.studentBaseUrl,
    );

    final queryParameters = <String, dynamic>{
      'schoolCode': schoolCode,
      'classroomCode': classroomCode,
    };

    if (firstName != null && firstName.trim().isNotEmpty) {
      queryParameters['firstName'] = firstName.trim();
    }
    if (lastName != null && lastName.trim().isNotEmpty) {
      queryParameters['lastName'] = lastName.trim();
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (attendanceStatus != null && attendanceStatus.isNotEmpty) {
      queryParameters['attendanceStatus'] = attendanceStatus;
    }
    if (tagCodes != null && tagCodes.isNotEmpty) {
      queryParameters['tagCodes'] = tagCodes;
    }
    if (guardianCodes != null && guardianCodes.isNotEmpty) {
      queryParameters['guardianCodes'] = guardianCodes;
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

  @override
  Future<StudentClassroomAssignResponseModel> assignStudentsToClassroom({
    required String classroomCode,
    required List<String> studentCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentClassroomAssignStudent,
      ApiConstants.studentBaseUrl,
    );

    final normStudentCodes = studentCodes
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final queryParameters = <String, dynamic>{
      'classroomCode': classroomCode.trim(),
      'studentCode': normStudentCodes,
    };

    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected student-classroom(assign) response format');
    }

    return StudentClassroomAssignResponseModel.fromJson(body);
  }
}


