import 'package:dio/dio.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../models/student_attendance_models.dart';
import '../models/student_absence_record_models.dart';
import '../models/staff_absence_record_models.dart';

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

  /// Student Sign-In form list - students that can be signed in for a date range.
  ///
  /// This follows the same paging structure as the custom view:
  /// data.content[] + pageable/number/size/totalPages/totalElements.
  Future<StudentAttendanceCustomPageModel> getStudentSignInFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });

  /// Student Sign-Out form list - students that can be signed out for a date range.
  ///
  /// Uses the same payload format as the sign-in form list/custom attendance view.
  Future<StudentAttendanceCustomPageModel> getStudentSignOutFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });

  /// Student Transfer form list - students that can be transferred for a date range.
  ///
  /// Payload and response follow the same structure as the custom attendance view.
  Future<StudentAttendanceCustomPageModel> getStudentTransferFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });

  /// Student Absent form list - students that are absent for a date range.
  ///
  /// This uses a dedicated endpoint that returns only absent students.
  Future<StudentAttendanceAbsentFormPageModel> getStudentAbsentFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });

  /// Student Absent toggle view - absent students for a date (used in Daily -> Show Absent toggle).
  ///
  /// Response shape matches [StudentAttendanceAbsentFormPageModel].
  Future<StudentAttendanceAbsentFormPageModel> getStudentAttendanceAbsentToggleView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });

  Future<StaffAttendanceDailyPageModel> getStaffAttendanceDaily({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });

  Future<StaffAttendanceDailyPageModel> getStaffAttendanceCustom({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });

  Future<StaffAttendanceDailyPageModel> getStaffSignInFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });

  Future<StaffAttendanceDailyPageModel> getStaffSignOutFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });

  Future<StaffAttendanceDailyPageModel> getStaffTransferFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });

  Future<StaffAttendanceAbsentPageModel> getStaffAttendanceAbsent({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });

  /// Staff Absent toggle view - absent staff for a date (used in Daily -> Show Absent toggle).
  ///
  /// Response shape matches [StaffAttendanceAbsentPageModel].
  Future<StaffAttendanceAbsentPageModel> getStaffAttendanceAbsentToggleView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  });

  /// Delete a single student attendance record (sign-in/sign-out entry).
  Future<void> deleteStudentAttendanceRecord({
    required String attendanceRecordCode,
    required String staffCode,
  });

  /// Marks students absent for a date range.
  Future<MarkAbsentResponseModel> markStudentsAbsent({
    required MarkAbsentRequestModel request,
  });

  /// Marks staff absent for a date range.
  Future<StaffMarkAbsentResponseModel> markStaffAbsent({
    required StaffMarkAbsentRequestModel request,
  });

  /// Expected attendance summary used for the daily "Expected Students" card.
  Future<StudentAttendanceExpectedSummaryModel>
      getStudentAttendanceExpectedSummaryCard();

  /// Staff expected attendance summary used for the daily "Expected Staff" card.
  Future<StaffAttendanceExpectedSummaryModel>
      getStaffAttendanceExpectedSummaryCard();

  /// Current-day sign-in status for one or more staff members.
  ///
  /// Returns a map of `staffCode -> status` where status is typically
  /// `SIGNED_IN` or `ABSENT`.
  Future<Map<String, String>> getStaffSignInStatus({
    required List<String> staffCodes,
  });

  /// Current-day sign-in status for one or more students.
  ///
  /// Returns a map of `studentCode -> status` where status is typically
  /// `SIGNED_IN` or `ABSENT`.
  Future<Map<String, String>> getStudentSignInStatus({
    required List<String> studentCodes,
  });

  /// Updates a single student attendance record (sign-in/sign-out entry).
  Future<String> updateStudentAttendanceRecord({
    required String attendanceRecordCode,
    required Map<String, dynamic> payload,
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

  @override
  Future<StudentAttendanceCustomPageModel> getStudentSignInFormList({
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
      ApiPaths.studentAttendanceSignInFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student sign-in form list API response format');
    }

    return StudentAttendanceCustomPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StudentAttendanceCustomPageModel> getStudentSignOutFormList({
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
      ApiPaths.studentAttendanceSignOutFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student sign-out form list API response format');
    }

    return StudentAttendanceCustomPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StudentAttendanceCustomPageModel> getStudentTransferFormList({
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
      ApiPaths.studentAttendanceTransferFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student transfer form list API response format');
    }

    return StudentAttendanceCustomPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StudentAttendanceAbsentFormPageModel> getStudentAbsentFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    final queryParameters = <String, dynamic>{
      'fromAbsenceDate': fromAbsenceDate,
      'toAbsenceDate': toAbsenceDate,
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
      ApiPaths.studentAttendanceAbsentFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student absent form list API response format');
    }

    return StudentAttendanceAbsentFormPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StudentAttendanceAbsentFormPageModel> getStudentAttendanceAbsentToggleView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    final queryParameters = <String, dynamic>{
      'fromAbsenceDate': fromAbsenceDate,
      'toAbsenceDate': toAbsenceDate,
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
      ApiPaths.studentAttendanceAbsentToggleView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student absent toggle API response format');
    }

    return StudentAttendanceAbsentFormPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffAttendanceDailyPageModel> getStaffAttendanceDaily({
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
      ApiPaths.staffAttendanceDailyView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff daily attendance API response format');
    }

    return StaffAttendanceDailyPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffAttendanceDailyPageModel> getStaffSignInFormList({
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
      ApiPaths.staffAttendanceSignInFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff sign-in form list API response format');
    }

    return StaffAttendanceDailyPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffAttendanceDailyPageModel> getStaffSignOutFormList({
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
      ApiPaths.staffAttendanceSignOutFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff sign-out form list API response format');
    }

    return StaffAttendanceDailyPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffAttendanceDailyPageModel> getStaffAttendanceCustom({
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
      ApiPaths.staffAttendanceCustomView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff custom attendance API response format');
    }

    return StaffAttendanceDailyPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffAttendanceDailyPageModel> getStaffTransferFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    final queryParameters = <String, dynamic>{
      'fromAbsenceDate': fromAbsenceDate,
      'toAbsenceDate': toAbsenceDate,
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
      ApiPaths.staffAttendanceTransferFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff transfer form list API response format');
    }

    return StaffAttendanceDailyPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffAttendanceAbsentPageModel> getStaffAttendanceAbsent({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    final queryParameters = <String, dynamic>{
      'fromAbsenceDate': fromAbsenceDate,
      'toAbsenceDate': toAbsenceDate,
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
      ApiPaths.staffAttendanceAbsentView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff absent list API response format');
    }

    return StaffAttendanceAbsentPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffAttendanceAbsentPageModel> getStaffAttendanceAbsentToggleView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) async {
    final queryParameters = <String, dynamic>{
      'fromAbsenceDate': fromAbsenceDate,
      'toAbsenceDate': toAbsenceDate,
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
      ApiPaths.staffAttendanceAbsentToggleView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff absent toggle API response format');
    }

    return StaffAttendanceAbsentPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<void> deleteStudentAttendanceRecord({
    required String attendanceRecordCode,
    required String staffCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.studentAttendanceRecords}/$attendanceRecordCode',
      ApiConstants.attendanceBaseUrl,
    );

    await _client.delete<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'staffCode': staffCode,
      },
    );
  }

  @override
  Future<MarkAbsentResponseModel> markStudentsAbsent({
    required MarkAbsentRequestModel request,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAbsenceRecordsMarkAbsent,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected mark-absent API response format');
    }

    return MarkAbsentResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffMarkAbsentResponseModel> markStaffAbsent({
    required StaffMarkAbsentRequestModel request,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAbsenceRecordsMarkAbsent,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: request.toJson(),
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff mark-absent API response format');
    }

    return StaffMarkAbsentResponseModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StudentAttendanceExpectedSummaryModel>
      getStudentAttendanceExpectedSummaryCard() async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceExpectedSummaryCard,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected expected attendance summary API response format',
      );
    }

    return StudentAttendanceExpectedSummaryModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffAttendanceExpectedSummaryModel>
      getStaffAttendanceExpectedSummaryCard() async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceExpectedSummaryCard,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(endpoint);

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected staff expected attendance summary API response format',
      );
    }

    return StaffAttendanceExpectedSummaryModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<Map<String, String>> getStaffSignInStatus({
    required List<String> staffCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceSignInStatus,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.post<Map<String, dynamic>>(
      endpoint,
      data: <String, dynamic>{
        'staffCodes': staffCodes,
      },
    );

    final data = response.data;
    if (data == null || data['data'] is! Map<String, dynamic>) {
      throw Exception('Unexpected staff sign-in status API response format');
    }

    final raw = data['data'] as Map<String, dynamic>;
    return raw.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Future<Map<String, String>> getStudentSignInStatus({
    required List<String> studentCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceSignInStatus,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.post<Map<String, dynamic>>(
      endpoint,
      data: <String, dynamic>{
        'studentCodes': studentCodes,
      },
    );

    final data = response.data;
    if (data == null || data['data'] is! Map<String, dynamic>) {
      throw Exception('Unexpected student sign-in status API response format');
    }

    final raw = data['data'] as Map<String, dynamic>;
    return raw.map((key, value) => MapEntry(key, value.toString()));
  }

  @override
  Future<String> updateStudentAttendanceRecord({
    required String attendanceRecordCode,
    required Map<String, dynamic> payload,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '${ApiPaths.studentAttendanceRecords}/$attendanceRecordCode',
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.patch<Map<String, dynamic>>(
      endpoint,
      data: payload,
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from update attendance record API');
    }

    // Top-level "message" field is used as success message per contract.
    return (data['message'] ?? 'Attendance updated successfully').toString();
  }
}
