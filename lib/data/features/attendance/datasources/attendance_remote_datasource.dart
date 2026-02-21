import 'package:dio/dio.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/student_attendance_models.dart';

abstract class AttendanceRemoteDataSource {
  Future<StudentAttendanceDailyPageModel> getStudentAttendanceDaily({
    required String attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  });

  Future<StudentAttendanceCustomPageModel> getStudentAttendanceCustom({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  AttendanceRemoteDataSourceImpl(this._client);

  final Dio _client;

  @override
  Future<StudentAttendanceDailyPageModel> getStudentAttendanceDaily({
    required String attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    final queryParameters = <String, dynamic>{
      // New backend contract expects from/to date range.
      // For the daily view we always send the SAME date for both.
      'fromAttendanceDate': attendanceDate,
      'toAttendanceDate': attendanceDate,
      // Backward-compatible pagination params
      'page': page,
      'size': size,
      // Pageable-style params (as shown in Swagger)
      'pageable.page': page,
      'pageable.size': size,
      // Dio encodes lists as repeated query params.
      'pageable.sort': <String>['studentName,asc'],
    };

    // Add classroomCodes if provided
    if (classroomCodes != null && classroomCodes.isNotEmpty) {
      queryParameters['classroomCodes'] = classroomCodes;
    }

    // Add tagCodes if provided
    if (tagCodes != null && tagCodes.isNotEmpty) {
      queryParameters['tagCodes'] = tagCodes;
    }

    // Add search if provided
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceDailyView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student attendance API response format');
    }

    return StudentAttendanceDailyPageModel.fromJson(
        response.data! as Map<String, dynamic>);
  }

  @override
  Future<StudentAttendanceCustomPageModel> getStudentAttendanceCustom({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    final queryParameters = <String, dynamic>{
      'fromAttendanceDate': fromAttendanceDate,
      'toAttendanceDate': toAttendanceDate,
      'page': page,
      'size': size,
    };

    if (classroomCodes != null && classroomCodes.isNotEmpty) {
      queryParameters['classroomCodes'] = classroomCodes;
    }

    if (tagCodes != null && tagCodes.isNotEmpty) {
      queryParameters['tagCodes'] = tagCodes;
    }

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    if (sort != null && sort.isNotEmpty) {
      queryParameters['sort'] = sort;
    }

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceCustomView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student custom attendance API response format');
    }

    return StudentAttendanceCustomPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }
}
