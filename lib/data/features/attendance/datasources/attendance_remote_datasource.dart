import 'package:dio/dio.dart';
import 'package:wowcare/core/util/idempotency_key.dart';
import '../../../../core/util/api_constants.dart';
import '../../../../core/util/api_paths.dart';
import '../../../../core/util/attendance_classroom_scope.dart';
import '../models/student_attendance_models.dart';
import '../models/student_absence_record_models.dart';
import '../models/staff_absence_record_models.dart';
import '../models/qr_validation_model.dart';

abstract class AttendanceRemoteDataSource {
  Future<StudentAttendanceDailyPageModel> getStudentAttendanceDaily({
    required String attendanceDate,
    String? fromAttendanceDate,
    String? toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int page = 0,
    int size = 10,
    required List<String> allowedClassroomCodes,
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
    required List<String> allowedClassroomCodes,
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
    required List<String> allowedClassroomCodes,
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
    required List<String> allowedClassroomCodes,
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
    required List<String> allowedClassroomCodes,
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
    required List<String> allowedClassroomCodes,
  });

  /// Student absent records for activity feed surfaces.
  ///
  /// Backend endpoint:
  /// `/api/v1/student-attendance/view/absent/records/activity`.
  Future<StudentAttendanceAbsentFormPageModel> getStudentAbsentRecordsActivity({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? studentCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
    required List<String> allowedClassroomCodes,
  });

  /// Student Absent toggle view - absent students for a date (used in Daily -> Show Absent toggle).
  ///
  /// Response shape matches [StudentAttendanceAbsentFormPageModel].
  Future<StudentAttendanceAbsentFormPageModel>
  getStudentAttendanceAbsentToggleView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
    required List<String> allowedClassroomCodes,
  });

  Future<StaffAttendanceDailyPageModel> getStaffAttendanceDaily({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
    required List<String> allowedClassroomCodes,
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
    required List<String> allowedClassroomCodes,
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
    required List<String> allowedClassroomCodes,
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
    required List<String> allowedClassroomCodes,
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
    required List<String> allowedClassroomCodes,
  });

  /// Staff Absent form list - staff that can be marked absent for a date range.
  ///
  /// Backend endpoint: `/api/v1/staff-attendance/absent/form/list`
  /// as exposed via [ApiPaths.staffAttendanceAbsentFormList].
  ///
  /// Response shape matches [StaffAttendanceAbsentPageModel].
  Future<StaffAttendanceAbsentPageModel> getStaffAbsentFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
    required List<String> allowedClassroomCodes,
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
    required List<String> allowedClassroomCodes,
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
    required List<String> allowedClassroomCodes,
  });

  /// Delete a single student attendance record (sign-in/sign-out entry).
  Future<void> deleteStudentAttendanceRecord({
    required String attendanceRecordCode,
    required String staffCode,
    required List<String> allowedClassroomCodes,
  });

  /// Delete a single student absence record (marked absent).
  Future<void> deleteStudentAbsenceRecord({
    required String absenceRecordCode,
    required String staffCode,
    required List<String> allowedClassroomCodes,
  });

  /// Delete a single staff attendance record (sign-in/sign-out/transfer entry).
  Future<void> deleteStaffAttendanceRecord({
    required String attendanceRecordCode,
    required String staffCode,
    required List<String> allowedClassroomCodes,
  });

  /// Delete a single staff absence record (marked absent) — admin override sign-in.
  Future<void> deleteStaffAbsenceRecord({
    required String absenceRecordCode,
    required String staffCode,
    required List<String> allowedClassroomCodes,
  });

  /// Marks students absent for a date range.
  Future<MarkAbsentResponseModel> markStudentsAbsent({
    required MarkAbsentRequestModel request,
    required List<String> allowedClassroomCodes,
  });

  /// Marks staff absent for a date range.
  Future<StaffMarkAbsentResponseModel> markStaffAbsent({
    required StaffMarkAbsentRequestModel request,
    required List<String> allowedClassroomCodes,
  });

  /// Expected attendance summary used for the daily "Expected Students" card.
  Future<StudentAttendanceExpectedSummaryModel>
  getStudentAttendanceExpectedSummaryCard({String? classroomCode});

  /// Staff expected attendance summary used for the daily "Expected Staff" card.
  Future<StaffAttendanceExpectedSummaryModel>
  getStaffAttendanceExpectedSummaryCard({String? classroomCode});

  /// Current-day sign-in status for one or more staff members.
  ///
  /// Returns a map of `staffCode -> status` where status is typically
  /// `SIGNED_IN` or `ABSENT`.
  Future<Map<String, String>> getStaffSignInStatus({
    required List<String> staffCodes,
    required List<String> allowedClassroomCodes,
  });

  /// Current-day sign-in status for one or more students.
  ///
  /// Returns a map of `studentCode -> status` where status is typically
  /// `SIGNED_IN` or `ABSENT`.
  Future<Map<String, String>> getStudentSignInStatus({
    required List<String> studentCodes,
    required List<String> allowedClassroomCodes,
  });

  /// Classroom-scoped "at time" student sign-in status.
  ///
  /// Moved verbatim from the activity attendance-window validator: POSTs to
  /// [ApiPaths.studentAttendanceSignInStatusAtTime] and parses the `data` map
  /// into `studentCode -> isPresent`, where a value of `true` counts as
  /// present.
  Future<Map<String, bool>> getStudentSignInStatusAtTime({
    required String classroomCode,
    required List<String> studentCodes,
    required DateTime instantUtc,
  });

  /// Classroom-scoped "at time" staff sign-in status.
  ///
  /// Moved verbatim from the activity attendance-window validator: POSTs to
  /// [ApiPaths.staffAttendanceSignInStatusAtTime] and parses the `data` map
  /// into `staffCode -> isPresent`, where a value of `true` OR the string
  /// `SIGNED_IN` counts as present.
  Future<Map<String, bool>> getStaffSignInStatusAtTime({
    required String classroomCode,
    required List<String> staffCodes,
    required DateTime instantUtc,
  });

  /// Updates a single student attendance record (sign-in/sign-out entry).
  Future<String> updateStudentAttendanceRecord({
    required String attendanceRecordCode,
    required Map<String, dynamic> payload,
    required List<String> allowedClassroomCodes,
  });

  /// Creates student sign-in records.
  ///
  /// Backend endpoint: `/api/v1/student-attendance-records/sign-in`.
  /// Returns a human-friendly success message from the API.
  Future<String> createStudentSignInRecords({
    required Map<String, dynamic> payload,
    required List<String> allowedClassroomCodes,
  });

  /// Posts a student sign-in request and returns the raw response map.
  ///
  /// Selects the parent or staff sign-in endpoint based on [isParent].
  Future<Map<String, dynamic>?> postStudentSignIn({
    required Map<String, dynamic> body,
    Map<String, dynamic>? queryParameters,
    required bool isParent,
    String? idempotencyKey,
  });

  /// Posts a student sign-out request (parent or staff endpoint).
  Future<Map<String, dynamic>?> postStudentSignOut({
    required Map<String, dynamic> body,
    Map<String, dynamic>? queryParameters,
    required bool isParent,
    String? idempotencyKey,
  });

  /// Posts a student classroom transfer request.
  Future<Map<String, dynamic>?> postStudentTransfer({
    required Map<String, dynamic> body,
    String? idempotencyKey,
  });

  /// Posts a staff sign-in request (admin bulk or teacher-self endpoint).
  Future<Map<String, dynamic>?> postStaffSignIn({
    required Map<String, dynamic> body,
    required bool isSelf,
    String? idempotencyKey,
  });

  /// Posts a staff sign-out request.
  /// Set [isSelf] to true to use the self sign-out endpoint.
  Future<Map<String, dynamic>?> postStaffSignOut({
    required Map<String, dynamic> body,
    bool isSelf = false,
    String? idempotencyKey,
  });

  /// Posts a staff classroom transfer request.
  Future<Map<String, dynamic>?> postStaffTransfer({
    required Map<String, dynamic> body,
    String? idempotencyKey,
  });

  /// Patches a staff daily attendance record identified by [rowCode].
  Future<Map<String, dynamic>?> patchStaffAttendanceDailyRecord({
    required String rowCode,
    required Map<String, dynamic> body,
  });

  /// GET student attendance profile (present-day summary + records).
  Future<Map<String, dynamic>?> getStudentAttendanceProfileRaw({
    required Map<String, dynamic> queryParameters,
  });

  /// GET student attendance profile absent-toggle list.
  Future<Map<String, dynamic>?> getStudentAttendanceProfileAbsentToggleRaw({
    required Map<String, dynamic> queryParameters,
  });

  /// GET staff attendance profile (present-day summary + records).
  Future<Map<String, dynamic>?> getStaffAttendanceProfileRaw({
    required Map<String, dynamic> queryParameters,
  });

  /// GET staff attendance profile absent-toggle list.
  Future<Map<String, dynamic>?> getStaffAttendanceProfileAbsentToggleRaw({
    required Map<String, dynamic> queryParameters,
  });

  /// GET student absent view list (paginated, filterable).
  Future<Map<String, dynamic>?> getStudentAttendanceAbsentViewRaw({
    required Map<String, dynamic> queryParameters,
  });

  Future<QrValidationResponseModel> validateQrCode({
    required String schoolCode,
    required String qrToken,
    required String useCase,
  });
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  AttendanceRemoteDataSourceImpl(this._client);

  final Dio _client;

  // Backend expects list-valued query params (classroomCodes, tagCodes,
  // allowedClassroomCodes, etc.) as ONE comma-joined value — confirmed
  // against a real request the backend actually filters by (e.g.
  // `classroomCodes=CLS_A,CLS_B,CLS_C`) — not as repeated `key[]=value`
  // pairs. `ListFormat.multiCompatible` produces the latter, which the
  // backend silently ignores, so multi-value filters (like selecting more
  // than one classroom) never actually narrowed the results.
  static final Options _attendanceListOptions = Options(
    listFormat: ListFormat.csv,
  );

  void _mergeAllowedClassroomCodes(
    Map<String, dynamic> queryParameters,
    List<String> allowedClassroomCodes,
  ) {
    if (allowedClassroomCodes.isEmpty) return;
    queryParameters['allowedClassroomCodes'] = List<String>.from(
      allowedClassroomCodes,
    );
  }

  void _applyAttendancePageableParams(
    Map<String, dynamic> queryParameters, {
    required int page,
    required int size,
    List<String>? sort,
    List<String> defaultSort = const <String>['studentName,asc'],
  }) {
    queryParameters['page'] = page;
    queryParameters['size'] = size;
    queryParameters['pageable.page'] = page;
    queryParameters['pageable.size'] = size;
    final effectiveSort = (sort != null && sort.isNotEmpty)
        ? sort
        : defaultSort;
    queryParameters['pageable.sort'] = effectiveSort;
    if (sort != null && sort.isNotEmpty) {
      queryParameters['sort'] = sort;
    }
  }

  @override
  Future<StudentAttendanceDailyPageModel> getStudentAttendanceDaily({
    required String attendanceDate,
    String? fromAttendanceDate,
    String? toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int page = 0,
    int size = 10,
    required List<String> allowedClassroomCodes,
  }) async {
    final queryParameters = <String, dynamic>{
      // New backend contract expects from/to date range.
      // For the daily view we always send the SAME date for both.
      'fromAttendanceDate': (fromAttendanceDate ?? attendanceDate),
      'toAttendanceDate': (toAttendanceDate ?? attendanceDate),
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
    if (studentCodes != null && studentCodes.isNotEmpty) {
      queryParameters['studentCodes'] = studentCodes;
    }

    // Add tagCodes if provided
    if (tagCodes != null && tagCodes.isNotEmpty) {
      queryParameters['tagCodes'] = tagCodes;
    }

    // Add search if provided
    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }
    if (signInAtFilter != null && signInAtFilter.isNotEmpty) {
      queryParameters['signInAtFilter'] = signInAtFilter;
    }
    if (signOutAtFilter != null && signOutAtFilter.isNotEmpty) {
      queryParameters['signOutAtFilter'] = signOutAtFilter;
    }
    if (isExpectedNotMarked == true) {
      queryParameters['isExpectedNotMarked'] = true;
    }

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceDailyView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected student attendance API response format');
    }

    return StudentAttendanceDailyPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
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
    required List<String> allowedClassroomCodes,
  }) async {
    final queryParameters = <String, dynamic>{
      'fromAttendanceDate': fromAttendanceDate,
      'toAttendanceDate': toAttendanceDate,
    };
    _applyAttendancePageableParams(
      queryParameters,
      page: page,
      size: size,
      sort: sort,
    );

    if (classroomCodes != null && classroomCodes.isNotEmpty) {
      queryParameters['classroomCodes'] = classroomCodes;
    }

    if (tagCodes != null && tagCodes.isNotEmpty) {
      queryParameters['tagCodes'] = tagCodes;
    }

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceCustomView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected student custom attendance API response format',
      );
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
    required List<String> allowedClassroomCodes,
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

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceSignInFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected student sign-in form list API response format',
      );
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
    required List<String> allowedClassroomCodes,
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

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceSignOutFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected student sign-out form list API response format',
      );
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
    required List<String> allowedClassroomCodes,
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

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceTransferFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected student transfer form list API response format',
      );
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
    required List<String> allowedClassroomCodes,
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

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceAbsentFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected student absent form list API response format',
      );
    }

    return StudentAttendanceAbsentFormPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StudentAttendanceAbsentFormPageModel> getStudentAbsentRecordsActivity({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? studentCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
    required List<String> allowedClassroomCodes,
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

    if (studentCodes != null && studentCodes.isNotEmpty) {
      queryParameters['studentCodes'] = studentCodes;
    }

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    if (sort != null && sort.isNotEmpty) {
      queryParameters['sort'] = sort;
    }

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceAbsentRecordsActivityView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected student absent activity records API response format',
      );
    }

    return StudentAttendanceAbsentFormPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StudentAttendanceAbsentFormPageModel>
  getStudentAttendanceAbsentToggleView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
    required List<String> allowedClassroomCodes,
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

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceAbsentToggleView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
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
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
    required List<String> allowedClassroomCodes,
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
    if (signInAtFilter != null && signInAtFilter.isNotEmpty) {
      queryParameters['signInAtFilter'] = signInAtFilter;
    }
    if (signOutAtFilter != null && signOutAtFilter.isNotEmpty) {
      queryParameters['signOutAtFilter'] = signOutAtFilter;
    }
    if (isExpectedNotMarked == true) {
      queryParameters['isExpectedNotMarked'] = true;
    }

    if (sort != null && sort.isNotEmpty) {
      queryParameters['sort'] = sort;
    }

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceDailyView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
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
    required List<String> allowedClassroomCodes,
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

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceSignInFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
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
    required List<String> allowedClassroomCodes,
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

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceSignOutFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected staff sign-out form list API response format',
      );
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
    required List<String> allowedClassroomCodes,
  }) async {
    final queryParameters = <String, dynamic>{
      'fromAttendanceDate': fromAttendanceDate,
      'toAttendanceDate': toAttendanceDate,
    };
    _applyAttendancePageableParams(
      queryParameters,
      page: page,
      size: size,
      sort: sort,
      defaultSort: const <String>['staffName,asc'],
    );

    if (classroomCodes != null && classroomCodes.isNotEmpty) {
      queryParameters['classroomCodes'] = classroomCodes;
    }

    if (tagCodes != null && tagCodes.isNotEmpty) {
      queryParameters['tagCodes'] = tagCodes;
    }

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceCustomView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
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
    required List<String> allowedClassroomCodes,
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

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceTransferFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception(
        'Unexpected staff transfer form list API response format',
      );
    }

    return StaffAttendanceDailyPageModel.fromJson(
      response.data! as Map<String, dynamic>,
    );
  }

  @override
  Future<StaffAttendanceAbsentPageModel> getStaffAbsentFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
    required List<String> allowedClassroomCodes,
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

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceAbsentFormList,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );

    if (response.data is! Map<String, dynamic>) {
      throw Exception('Unexpected staff absent form list API response format');
    }

    return StaffAttendanceAbsentPageModel.fromJson(
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
    required List<String> allowedClassroomCodes,
  }) async {
    final queryParameters = <String, dynamic>{
      'fromAbsenceDate': fromAbsenceDate,
      'toAbsenceDate': toAbsenceDate,
    };
    _applyAttendancePageableParams(
      queryParameters,
      page: page,
      size: size,
      sort: sort,
      defaultSort: const <String>['staffName,asc'],
    );

    if (classroomCodes != null && classroomCodes.isNotEmpty) {
      queryParameters['classroomCodes'] = classroomCodes;
    }

    if (tagCodes != null && tagCodes.isNotEmpty) {
      queryParameters['tagCodes'] = tagCodes;
    }

    if (search != null && search.isNotEmpty) {
      queryParameters['search'] = search;
    }

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceAbsentView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
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
    required List<String> allowedClassroomCodes,
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

    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceAbsentToggleView,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
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
    required List<String> allowedClassroomCodes,
  }) async {
    final queryParameters = <String, dynamic>{'staffCode': staffCode};
    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceDailyRecordByRowCode(attendanceRecordCode),
      ApiConstants.attendanceBaseUrl,
    );
    await _client.delete<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );
  }

  @override
  Future<void> deleteStudentAbsenceRecord({
    required String absenceRecordCode,
    required String staffCode,
    required List<String> allowedClassroomCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAbsenceRecordByCode(absenceRecordCode),
      ApiConstants.attendanceBaseUrl,
    );

    final queryParameters = <String, dynamic>{'staffCode': staffCode};
    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    await _client.delete<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );
  }

  @override
  Future<void> deleteStaffAttendanceRecord({
    required String attendanceRecordCode,
    required String staffCode,
    required List<String> allowedClassroomCodes,
  }) async {
    final queryParameters = <String, dynamic>{'staffCode': staffCode};
    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceDailyRecordByRowCode(attendanceRecordCode),
      ApiConstants.attendanceBaseUrl,
    );
    await _client.delete<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );
  }

  @override
  Future<void> deleteStaffAbsenceRecord({
    required String absenceRecordCode,
    required String staffCode,
    required List<String> allowedClassroomCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAbsenceRecordByCode(absenceRecordCode),
      ApiConstants.attendanceBaseUrl,
    );

    final queryParameters = <String, dynamic>{'staffCode': staffCode};
    _mergeAllowedClassroomCodes(queryParameters, allowedClassroomCodes);

    await _client.delete<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );
  }

  @override
  Future<MarkAbsentResponseModel> markStudentsAbsent({
    required MarkAbsentRequestModel request,
    required List<String> allowedClassroomCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAbsenceRecordsMarkAbsent,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        ...request.toJson(),
        'allowedClassroomCodes': List<String>.from(allowedClassroomCodes),
      },
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
    required List<String> allowedClassroomCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAbsenceRecordsMarkAbsent,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        ...request.toJson(),
        'allowedClassroomCodes': List<String>.from(allowedClassroomCodes),
      },
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
  getStudentAttendanceExpectedSummaryCard({String? classroomCode}) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceExpectedSummaryCard,
      ApiConstants.attendanceBaseUrl,
    );

    final queryParameters = <String, dynamic>{};
    final code = classroomCode?.trim();
    if (code != null && code.isNotEmpty) {
      queryParameters['classroomCode'] = code;
    }

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );

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
  getStaffAttendanceExpectedSummaryCard({String? classroomCode}) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceExpectedSummaryCard,
      ApiConstants.attendanceBaseUrl,
    );

    final queryParameters = <String, dynamic>{};
    final code = classroomCode?.trim();
    if (code != null && code.isNotEmpty) {
      queryParameters['classroomCode'] = code;
    }

    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: _attendanceListOptions,
    );

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
    required List<String> allowedClassroomCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceSignInStatus,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.post<Map<String, dynamic>>(
      endpoint,
      data: <String, dynamic>{
        'staffCodes': staffCodes,
        'allowedClassroomCodes': List<String>.from(allowedClassroomCodes),
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
    required List<String> allowedClassroomCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceSignInStatus,
      ApiConstants.attendanceBaseUrl,
    );

    final response = await _client.post<Map<String, dynamic>>(
      endpoint,
      data: <String, dynamic>{
        'studentCodes': studentCodes,
        'allowedClassroomCodes': List<String>.from(allowedClassroomCodes),
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
  Future<Map<String, bool>> getStudentSignInStatusAtTime({
    required String classroomCode,
    required List<String> studentCodes,
    required DateTime instantUtc,
  }) async {
    if (studentCodes.isEmpty) return const <String, bool>{};
    final endpoint = ApiPaths.url(ApiPaths.studentAttendanceSignInStatusAtTime);
    final response = await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'classroomCode': classroomCode,
        'studentCodes': studentCodes,
        'instant': instantUtc.toIso8601String(),
      },
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) return const <String, bool>{};
    final data = root['data'];
    if (data is! Map) return const <String, bool>{};
    return data.map<String, bool>((key, value) {
      final code = key.toString().trim();
      final isPresent = value == true;
      return MapEntry(code, isPresent);
    });
  }

  @override
  Future<Map<String, bool>> getStaffSignInStatusAtTime({
    required String classroomCode,
    required List<String> staffCodes,
    required DateTime instantUtc,
  }) async {
    if (staffCodes.isEmpty) return const <String, bool>{};
    final endpoint = ApiPaths.url(ApiPaths.staffAttendanceSignInStatusAtTime);
    final response = await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'classroomCode': classroomCode,
        'staffCodes': staffCodes,
        'instant': instantUtc.toIso8601String(),
      },
    );
    final root = response.data;
    if (root is! Map<String, dynamic>) return const <String, bool>{};
    final data = root['data'];
    if (data is! Map) return const <String, bool>{};
    return data.map<String, bool>((key, value) {
      final code = key.toString().trim();
      final isPresent =
          value == true || value.toString().toUpperCase() == 'SIGNED_IN';
      return MapEntry(code, isPresent);
    });
  }

  @override
  Future<String> updateStudentAttendanceRecord({
    required String attendanceRecordCode,
    required Map<String, dynamic> payload,
    required List<String> allowedClassroomCodes,
  }) async {
    final body = Map<String, dynamic>.from(payload)
      ..['allowedClassroomCodes'] = List<String>.from(allowedClassroomCodes);

    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceDailyRecordByRowCode(attendanceRecordCode),
      ApiConstants.attendanceBaseUrl,
    );
    final response = await _client.patch<Map<String, dynamic>>(
      endpoint,
      data: body,
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from update attendance record API');
    }

    // Top-level "message" field is used as success message per contract.
    return (data['message'] ?? 'Attendance updated successfully').toString();
  }

  @override
  Future<String> createStudentSignInRecords({
    required Map<String, dynamic> payload,
    required List<String> allowedClassroomCodes,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceRecordsSignIn,
      ApiConstants.attendanceBaseUrl,
    );

    final body = Map<String, dynamic>.from(payload)
      ..['allowedClassroomCodes'] = List<String>.from(allowedClassroomCodes);

    final response = await _client.post<Map<String, dynamic>>(
      endpoint,
      data: body,
    );

    final data = response.data;
    if (data == null) {
      throw Exception('Empty response from student sign-in API');
    }
    return (data['message'] ?? 'Signed in successfully').toString();
  }

  @override
  Future<Map<String, dynamic>?> postStudentSignIn({
    required Map<String, dynamic> body,
    Map<String, dynamic>? queryParameters,
    required bool isParent,
    String? idempotencyKey,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      isParent
          ? ApiPaths.studentAttendanceRecordsParentSignIn
          : ApiPaths.studentAttendanceRecordsSignIn,
      ApiConstants.attendanceBaseUrl,
    );
    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      data: body,
      options: idempotencyKey != null
          ? Options(headers: {IdempotencyKey.headerName: idempotencyKey})
          : null,
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  @override
  Future<Map<String, dynamic>?> postStudentSignOut({
    required Map<String, dynamic> body,
    Map<String, dynamic>? queryParameters,
    required bool isParent,
    String? idempotencyKey,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      isParent
          ? ApiPaths.studentAttendanceRecordsParentSignOut
          : ApiPaths.studentAttendanceRecordsSignOut,
      ApiConstants.attendanceBaseUrl,
    );
    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      data: body,
      options: idempotencyKey != null
          ? Options(headers: {IdempotencyKey.headerName: idempotencyKey})
          : null,
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  @override
  Future<Map<String, dynamic>?> postStudentTransfer({
    required Map<String, dynamic> body,
    String? idempotencyKey,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.studentAttendanceRecordsTransfer,
      ApiConstants.attendanceBaseUrl,
    );
    final response = await _client.post<dynamic>(
      endpoint,
      data: body,
      options: idempotencyKey != null
          ? Options(headers: {IdempotencyKey.headerName: idempotencyKey})
          : null,
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  @override
  Future<Map<String, dynamic>?> postStaffSignIn({
    required Map<String, dynamic> body,
    required bool isSelf,
    String? idempotencyKey,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      isSelf
          ? ApiPaths.staffAttendanceRecordsSignInSelf
          : ApiPaths.staffAttendanceRecordsSignIn,
      ApiConstants.attendanceBaseUrl,
    );
    final response = await _client.post<dynamic>(
      endpoint,
      data: body,
      options: idempotencyKey != null
          ? Options(headers: {IdempotencyKey.headerName: idempotencyKey})
          : null,
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  @override
  Future<Map<String, dynamic>?> postStaffSignOut({
    required Map<String, dynamic> body,
    bool isSelf = false,
    String? idempotencyKey,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      isSelf
          ? ApiPaths.staffAttendanceRecordsSignOutSelf
          : ApiPaths.staffAttendanceRecordsSignOut,
      ApiConstants.attendanceBaseUrl,
    );
    final response = await _client.post<dynamic>(
      endpoint,
      data: body,
      options: idempotencyKey != null
          ? Options(headers: {IdempotencyKey.headerName: idempotencyKey})
          : null,
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  @override
  Future<Map<String, dynamic>?> postStaffTransfer({
    required Map<String, dynamic> body,
    String? idempotencyKey,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceRecordsTransfer,
      ApiConstants.attendanceBaseUrl,
    );
    final response = await _client.post<dynamic>(
      endpoint,
      data: body,
      options: idempotencyKey != null
          ? Options(headers: {IdempotencyKey.headerName: idempotencyKey})
          : null,
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  @override
  Future<Map<String, dynamic>?> patchStaffAttendanceDailyRecord({
    required String rowCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceDailyRecordByRowCode(rowCode),
      ApiConstants.attendanceBaseUrl,
    );
    final response = await _client.patch<Map<String, dynamic>>(
      endpoint,
      data: body,
    );
    return response.data;
  }

  /// Performs an attendance list GET with the shared query options and returns
  /// the raw response map (or null when the payload is not a JSON object).
  Future<Map<String, dynamic>?> _attendanceListGet(
    String path,
    Map<String, dynamic> queryParameters,
  ) async {
    final endpoint = ApiPaths.urlWithBase(path, ApiConstants.attendanceBaseUrl);
    final response = await _client.get<dynamic>(
      endpoint,
      queryParameters: queryParameters,
      options: attendanceListQueryOptions,
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }

  @override
  Future<Map<String, dynamic>?> getStudentAttendanceProfileRaw({
    required Map<String, dynamic> queryParameters,
  }) => _attendanceListGet(ApiPaths.studentAttendanceProfile, queryParameters);

  @override
  Future<Map<String, dynamic>?> getStudentAttendanceProfileAbsentToggleRaw({
    required Map<String, dynamic> queryParameters,
  }) => _attendanceListGet(
    ApiPaths.studentAttendanceProfileAbsentToggle,
    queryParameters,
  );

  @override
  Future<Map<String, dynamic>?> getStaffAttendanceProfileRaw({
    required Map<String, dynamic> queryParameters,
  }) => _attendanceListGet(ApiPaths.staffAttendanceProfile, queryParameters);

  @override
  Future<Map<String, dynamic>?> getStaffAttendanceProfileAbsentToggleRaw({
    required Map<String, dynamic> queryParameters,
  }) => _attendanceListGet(
    ApiPaths.staffAttendanceProfileAbsentToggle,
    queryParameters,
  );

  @override
  Future<Map<String, dynamic>?> getStudentAttendanceAbsentViewRaw({
    required Map<String, dynamic> queryParameters,
  }) =>
      _attendanceListGet(ApiPaths.studentAttendanceAbsentView, queryParameters);

  @override
  Future<QrValidationResponseModel> validateQrCode({
    required String schoolCode,
    required String qrToken,
    required String useCase,
  }) async {
    final endpoint = ApiConstants.qrCodeValidateEndpoint(schoolCode);
    final body = QrValidationRequestModel(
      qrToken: qrToken,
      useCase: useCase,
    ).toJson();
    final response = await _client.post<dynamic>(endpoint, data: body);
    if (response.data is! Map<String, dynamic>) {
      throw Exception('Invalid QR validation response');
    }
    return QrValidationResponseModel.fromJson(
      response.data as Map<String, dynamic>,
    );
  }
}
