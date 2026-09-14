import 'package:dio/dio.dart';

import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/api_constants.dart';
import '../../../../core/utils/api_paths.dart';
import '../../../../core/utils/storage_keys.dart';
import '../models/student_classroom_models.dart';

abstract class StudentClassroomRemoteDataSource {
  /// Calls `GET /api/v1/student-classroom` with the given filters.
  Future<List<StudentClassroomItemModel>> getStudentClassroomList({
    required String schoolCode,
    required String classroomCode,
    String? firstName,
    String? lastName,
    String? search,
    List<String>? studentCodes,
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
  StudentClassroomRemoteDataSourceImpl(this._client, this._storage);

  final Dio _client;
  final StorageService _storage;

  Future<Map<String, dynamic>> _buildScopeHeaders({
    required String fallbackSchoolCode,
  }) async {
    final storedOrganizationCode =
        (await _storage.getString(StorageKeys.organizationCode) ?? '').trim();
    final storedSchoolCode =
        (await _storage.getString(StorageKeys.schoolCode) ?? '').trim();

    final resolvedOrganizationCode = storedOrganizationCode;
    final resolvedSchoolCode = storedSchoolCode.isNotEmpty
        ? storedSchoolCode
        : fallbackSchoolCode.trim();

    final headers = <String, dynamic>{
      'accept': 'application/json',
    };
    if (resolvedSchoolCode.isNotEmpty) {
      headers['X-School-Code'] = resolvedSchoolCode;
      headers['x-school-code'] = resolvedSchoolCode;
      headers['schoolCode'] = resolvedSchoolCode;
    }
    if (resolvedOrganizationCode.isNotEmpty) {
      headers['X-Organization-Code'] = resolvedOrganizationCode;
      headers['x-organization-code'] = resolvedOrganizationCode;
      headers['organizationCode'] = resolvedOrganizationCode;
    }
    return headers;
  }

  @override
  Future<List<StudentClassroomItemModel>> getStudentClassroomList({
    required String schoolCode,
    required String classroomCode,
    String? firstName,
    String? lastName,
    String? search,
    List<String>? studentCodes,
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
      'sort': 'name,asc',
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
    if (studentCodes != null && studentCodes.isNotEmpty) {
      queryParameters['studentCodes'] = studentCodes
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    if (status != null && status.isNotEmpty) {
      queryParameters['status'] = status;
    }
    if (studentCodes != null && studentCodes.isNotEmpty) {
      final normalized = studentCodes
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (normalized.isNotEmpty) {
        queryParameters['studentCodes'] = normalized;
      }
    }
    // Keep payload strictly aligned with backend request DTO for this API.
    if (tagCodes != null && tagCodes.isNotEmpty) {
      queryParameters['tagCodes'] = tagCodes;
    }
    if (guardianCodes != null && guardianCodes.isNotEmpty) {
      queryParameters['guardianCodes'] = guardianCodes;
    }

    final headers = await _buildScopeHeaders(fallbackSchoolCode: schoolCode);

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: Options(
        headers: headers,
        listFormat: ListFormat.multiCompatible,
      ),
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

    final headers = await _buildScopeHeaders(fallbackSchoolCode: '');

    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: Options(headers: headers),
    );

    final body = response.data;
    if (body is! Map<String, dynamic>) {
      throw Exception('Unexpected student-classroom(assign) response format');
    }

    return StudentClassroomAssignResponseModel.fromJson(body);
  }
}


