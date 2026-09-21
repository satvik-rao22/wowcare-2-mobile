import 'package:dio/dio.dart';
import 'package:wowcare/core/utils/api_constants.dart';
import 'package:wowcare/core/utils/api_paths.dart';

/// Calls the overtime endpoints using the host app's Dio client (so the auth +
/// org/school header interceptors apply automatically).
///
/// Two steps: [calculate] recomputes overtime into the backend table, then
/// [getOverview] reads the calculated result.
class StaffOvertimeRemoteDataSource {
  StaffOvertimeRemoteDataSource(this._client);

  final Dio _client;

  static const String _overviewPath = '/api/v1/staff-overtime-records/profile';
  static const String _calculatePath =
      '/api/v1/staff-overtime-records/calculate';

  /// Triggers a server-side recompute for the range. Note: `staffCode` is sent
  /// as an array here (the calculate endpoint accepts a batch).
  Future<void> calculate({
    required String staffCode,
    required String fromDate,
    required String toDate,
  }) async {
    final endpoint =
        ApiPaths.urlWithBase(_calculatePath, ApiConstants.attendanceBaseUrl);
    await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'staffCode': <String>[staffCode],
        'fromDate': fromDate,
        'toDate': toDate,
      },
    );
  }

  /// Edits a single attendance (sign-in/out) record. [body] already contains
  /// the UTC `signedInAt`/`signedOutAt`, methods and `timeZone`.
  Future<void> editDailyRecord({
    required String recordCode,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceDailyRecordByRowCode(recordCode),
      ApiConstants.attendanceBaseUrl,
    );
    await _client.patch<dynamic>(endpoint, data: body);
  }

  /// Deletes a single attendance (sign-in/out) record. `staffCode` goes as a
  /// query param (matching the backend's delete contract).
  Future<void> deleteDailyRecord({
    required String recordCode,
    required String staffCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      ApiPaths.staffAttendanceDailyRecordByRowCode(recordCode),
      ApiConstants.attendanceBaseUrl,
    );
    await _client.delete<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{'staffCode': staffCode},
    );
  }

  /// Edits an absence record. [body] carries from/to dates, reason, type, note.
  Future<void> editAbsence({
    required String code,
    required Map<String, dynamic> body,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '/api/v1/staff-absence-records/$code',
      ApiConstants.attendanceBaseUrl,
    );
    await _client.patch<dynamic>(endpoint, data: body);
  }

  /// Deletes an absence record. `staffCode` is a query param.
  Future<void> deleteAbsence({
    required String code,
    required String staffCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '/api/v1/staff-absence-records/$code',
      ApiConstants.attendanceBaseUrl,
    );
    await _client.delete<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{'staffCode': staffCode},
    );
  }

  /// Syncs the staff-shift calendar's absent days (staff service). Best-effort
  /// follow-up after an absence edit so the schedule stays aligned.
  Future<void> markAbsentDays({
    required String staffCode,
    required List<String> absentDates,
    required String schoolCode,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '/api/v1/staff-shifts/absent-days',
      ApiConstants.staffBaseUrl,
    );
    await _client.post<dynamic>(
      endpoint,
      data: <String, dynamic>{
        'staffCode': staffCode,
        'absentDates': absentDates,
        'schoolCode': schoolCode,
      },
    );
  }

  /// Fetches active classrooms/locations for the school (own call so the
  /// module stays independent). Returns raw `{code, name}` maps.
  Future<List<Map<String, dynamic>>> getClassroomsRaw({
    required String schoolCode,
  }) async {
    final uri = Uri.parse(ApiPaths.url(ApiPaths.classroomAll)).replace(
      queryParameters: <String, String>{
        'school': schoolCode,
        'status': 'ACTIVE',
        'sortByName': 'asc',
      },
    );
    final res = await _client.getUri<dynamic>(uri);
    final body = res.data;
    final root = body is Map ? (body['data'] ?? body) : body;
    final list = root is Map ? (root['content'] as List?) : (root as List?);
    return (list ?? const [])
        .whereType<Map>()
        .map((e) {
          final m = e.cast<String, dynamic>();
          return <String, dynamic>{
            'code': (m['code'] ?? m['classroomCode'])?.toString() ?? '',
            'name': (m['name'] ?? m['classroomName'])?.toString() ?? '',
          };
        })
        .where((m) => (m['code'] as String).isNotEmpty)
        .toList();
  }

  /// Fetches active staff for the school (own call so the module stays
  /// independent) for the admin "switch staff" picker. Returns raw
  /// `{code, name, designation, classroom}` maps.
  Future<List<Map<String, dynamic>>> getStaffRaw({
    required String schoolCode,
    String organizationCode = '',
  }) async {
    final endpoint =
        ApiPaths.urlWithBase(ApiPaths.staffList, ApiConstants.staffBaseUrl);
    final res = await _client.get<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'schoolCode': schoolCode,
        'page': 0,
        'size': 200,
        'sort': 'firstName,asc',
        'status': <String>['ACTIVE'],
        if (organizationCode.isNotEmpty) 'organizationCode': organizationCode,
      },
      // Repeats keys: `status=ACTIVE&status=UPCOMING`.
      options: Options(listFormat: ListFormat.multi),
    );
    final body = res.data;
    final data = body is Map ? body['data'] : null;
    final list = data is List
        ? data
        : (data is Map ? (data['content'] as List?) : null);
    return (list ?? const [])
        .whereType<Map>()
        .map((e) {
          final m = e.cast<String, dynamic>();
          final primary = m['primaryClassroom'];
          final classroom = primary is Map
              ? (primary['name'] ?? primary['classroomName'])?.toString()
              : null;
          return <String, dynamic>{
            'code': (m['code'] ?? m['staffCode'])?.toString() ?? '',
            'name': (m['name'] ?? '').toString(),
            'designation': (m['designation'] ?? '').toString(),
            'classroom': (classroom ?? '').toString(),
          };
        })
        .where((m) =>
            (m['code'] as String).isNotEmpty &&
            (m['name'] as String).trim().isNotEmpty)
        .toList();
  }

  /// Records a sign-in (admin-added session). [occurredAtUtc] is ISO-8601 UTC.
  Future<void> signIn({
    required String staffCode,
    required String classroomCode,
    required String attendanceDate,
    required String occurredAtUtc,
    required String timeZone,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '/api/v1/staff-attendance-records/sign-in',
      ApiConstants.attendanceBaseUrl,
    );
    await _client.post<dynamic>(endpoint, data: _sessionBody(
      staffCode: staffCode,
      classroomCode: classroomCode,
      attendanceDate: attendanceDate,
      occurredAtUtc: occurredAtUtc,
      timeZone: timeZone,
      isSignIn: true,
    ));
  }

  /// Records a sign-out (admin-added). [occurredAtUtc] is ISO-8601 UTC.
  Future<void> signOut({
    required String staffCode,
    required String classroomCode,
    required String attendanceDate,
    required String occurredAtUtc,
    required String timeZone,
  }) async {
    final endpoint = ApiPaths.urlWithBase(
      '/api/v1/staff-attendance-records/sign-out',
      ApiConstants.attendanceBaseUrl,
    );
    await _client.post<dynamic>(endpoint, data: _sessionBody(
      staffCode: staffCode,
      classroomCode: classroomCode,
      attendanceDate: attendanceDate,
      occurredAtUtc: occurredAtUtc,
      timeZone: timeZone,
      isSignIn: false,
    ));
  }

  Map<String, dynamic> _sessionBody({
    required String staffCode,
    required String classroomCode,
    required String attendanceDate,
    required String occurredAtUtc,
    required String timeZone,
    required bool isSignIn,
  }) {
    return <String, dynamic>{
      if (isSignIn) 'isExpectedToday': true,
      'attendanceDate': attendanceDate,
      'staffCode': staffCode,
      'staffCodes': <String>[staffCode],
      'classroomCode': classroomCode,
      'classroomCodeByStaffCode': <String, String>{staffCode: classroomCode},
      'method': 'APP',
      'latitude': 0,
      'longitude': 0,
      'withinGeofence': false,
      'timeZone': timeZone,
      'occurredAt': occurredAtUtc,
      'allowedClassroomCodes': <String>[],
    };
  }

  /// Reads the calculated per-day overview. The endpoint is paginated
  /// (server default 10/page); [page]/[size] go as query params (Spring
  /// pageable) and the [overtimeOnly]/[absentOnly] filters in the body.
  Future<Map<String, dynamic>?> getOverview({
    required String staffCode,
    required String fromDate,
    required String toDate,
    int page = 0,
    int size = 10,
    bool overtimeOnly = false,
    bool absentOnly = false,
  }) async {
    final endpoint =
        ApiPaths.urlWithBase(_overviewPath, ApiConstants.attendanceBaseUrl);
    final response = await _client.post<dynamic>(
      endpoint,
      queryParameters: <String, dynamic>{
        'page': page,
        'size': size,
        'sort': 'date,desc',
      },
      data: <String, dynamic>{
        'staffCode': staffCode,
        'fromDate': fromDate,
        'toDate': toDate,
        'overtimeOnly': overtimeOnly,
        'absentOnly': absentOnly,
      },
    );
    final data = response.data;
    return data is Map<String, dynamic> ? data : null;
  }
}
