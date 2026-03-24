import 'api_constants.dart';

/// REST paths are built with [v1]. When [includeMicroserviceSegmentInPath] is true
/// (default), paths are `/api/v1/{microservice}/…`. When false, `/api/v1/{tail}` only
/// (no microservice segment). Use [url] / [urlWithBase] for the host from
/// [ApiConstants.baseUrlForMicroservice]. Pass [microserviceKey] to [url] if host
/// selection is wrong for a custom compact path.
class ApiPaths {
  ApiPaths._();

  /// If true (default), [v1] yields `/api/v1/{microservice}/…`. If false, yields
  /// `/api/v1/{tail}` (empty [tail] still uses `/api/v1/{microservice}`).
  static bool includeMicroserviceSegmentInPath = false;

  static const Set<String> _knownMicroserviceKeys = {
    ApiMicroservices.user,
    ApiMicroservices.organization,
    ApiMicroservices.school,
    ApiMicroservices.staff,
    ApiMicroservices.student,
    ApiMicroservices.classroom,
    ApiMicroservices.attendance,
    ApiMicroservices.activity,
  };

  /// `/api/v1/{ms}` or `/api/v1/{ms}/{tail}` when [includeMicroserviceSegmentInPath];
  /// otherwise `/api/v1/{ms}` or `/api/v1/{tail}`.
  static String v1(String microservice, [String tail = '']) {
    if (tail.isEmpty) return '/api/v1/$microservice';
    final t = tail.startsWith('/') ? tail.substring(1) : tail;
    if (includeMicroserviceSegmentInPath) {
      return '/api/v1/$microservice/$t';
    }
    return '/api/v1/$t';
  }

  /// Host routing key for [path]. With compact paths ([includeMicroserviceSegmentInPath]
  /// false), uses the first segment after `/api/v1/` when it matches [ApiMicroservices],
  /// else [microserviceFromCompactResourcePrefix]. [microserviceKey] overrides parsing.
  static String microserviceKeyFromPath(
    String path, {
    String? microserviceKey,
  }) {
    if (microserviceKey != null) return microserviceKey;
    final p = path.startsWith('/') ? path : '/$path';
    final parts = p.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length < 3 || parts[0] != 'api' || parts[1] != 'v1') {
      return ApiMicroservices.user;
    }
    final seg2 = parts[2];
    if (includeMicroserviceSegmentInPath) {
      return seg2;
    }
    if (_knownMicroserviceKeys.contains(seg2)) return seg2;
    return _microserviceFromCompactResourcePrefix(seg2);
  }

  static String _microserviceFromCompactResourcePrefix(String firstSegment) {
    switch (firstSegment) {
      case 'auth':
      case 'users':
      case 'organizations':
      case 'school-users':
      case 'physicians':
      case 'guardian':
      case 'guardian-user':
      case 'tags':
      case 'pickup':
        return ApiMicroservices.user;
      case 'schools':
        return ApiMicroservices.school;
      case 'school':
        return ApiMicroservices.organization;
      case 'staff-classrooms':
      case 'staff-documents':
      case 'staff-dates':
      case 'staff-address':
      case 'staff-schedules':
      case 'my-profile':
        return ApiMicroservices.staff;
      case 'student-classroom':
      case 'student-documents':
      case 'regular-schedules':
      case 'student-tags':
        return ApiMicroservices.student;
      case 'student-attendance':
      case 'student-absence-records':
      case 'staff-attendance':
        return ApiMicroservices.attendance;
      case 'classrooms':
      case 'activities':
      case 'activity-types':
        return ApiMicroservices.activity;
      default:
        return ApiMicroservices.user;
    }
  }

  /// Full URL: host from [ApiConstants.baseUrlForMicroservice] + [path].
  static String url(String path, {String? microserviceKey}) {
    final p = path.startsWith('/') ? path : '/$path';
    final ms = microserviceKeyFromPath(p, microserviceKey: microserviceKey);
    return '${ApiConstants.baseUrlForMicroservice(ms)}$p';
  }

  /// Same as [url]; the [baseUrl] argument is ignored (kept so existing call sites
  /// keep compiling). Optional [microserviceKey] overrides host detection for [path].
  static String urlWithBase(
    String path,
    String baseUrl, {
    String? microserviceKey,
  }) =>
      url(path, microserviceKey: microserviceKey);

  // —— Auth (user MS) ——
  static String get authLogin => v1(ApiMicroservices.user, 'auth/login');
  static String get authLogout => v1(ApiMicroservices.user, 'auth/logout');
  static String get authForgotPassword =>
      v1(ApiMicroservices.user, 'auth/forgot-password');
  static String get authLoginContext =>
      v1(ApiMicroservices.user, 'auth/login-context');

  // —— Users ——
  static String get userRoot => v1(ApiMicroservices.user, 'users');
  static String userEmailChange(String userCode) =>
      '$userRoot/$userCode/email-change';

  // —— School MS ——
  static String get schoolNamesByOrg =>
      v1(ApiMicroservices.school, 'schools/names-by-org');
  static String schoolNamesByOrgPath(String orgCode) =>
      '$schoolNamesByOrg/$orgCode';

  static String get organizationNames =>
      v1(ApiMicroservices.user, 'organizations/names');

  static String get schools => v1(ApiMicroservices.school, 'schools');
  static String schoolByCode(String schoolCode) => '$schools/$schoolCode';

  /// School-wide regular schedule (operating hours per weekday).
  /// Actual: GET /api/v1/organization/school/{schoolCode}/regular-schedule
  static String schoolRegularSchedule(String schoolCode) => v1(
        ApiMicroservices.organization,
        'school/$schoolCode/regular-schedule',
      );

  // —— Staff MS ——
  /// Paginated staff list — UAT: **`GET /api/v1/staff/staff`** (not `…/staff` alone).
  static String get staffList => v1(ApiMicroservices.staff, 'staff');
  static String get staffClassrooms =>
      v1(ApiMicroservices.staff, 'staff-classrooms');
  static String get staffClassroomsAssignStaff =>
      v1(ApiMicroservices.staff, 'staff-classrooms/assign-staff');
  /// Staff totals — UAT: **`/api/v1/staff/staff/count`** (not `…/staff/count`, which
  /// resolves as `api/v1/count` on the gateway).
  static String get staffCount => v1(ApiMicroservices.staff, 'staff/count');
  static String get staffProfile => staffList;
  /// Legacy single-segment path; prefer [staffProfilePath] / [staffMyProfilePinPath] for UAT.
  static String get staffMyProfile =>
      v1(ApiMicroservices.staff, 'my-profile');

  /// GET/PATCH staff profile (my-profile) — **`/api/v1/staff/staff/my-profile/{staffCode}`**
  /// For logged-in user's own profile.
  static String staffProfilePath(String staffCode) =>
      v1(ApiMicroservices.staff, 'staff/my-profile/$staffCode');

  /// GET staff profile (edit staff) — **`/api/v1/staff/staff/{staffCode}/profile`**
  /// For viewing/editing another staff member's profile details.
  static String staffProfileByCodePath(String staffCode) =>
      v1(ApiMicroservices.staff, 'staff/$staffCode/profile');

  /// GET sign-in PIN — **`/api/v1/staff/staff/my-profile/{staffCode}/pin`**.
  static String staffMyProfilePinPath(String staffCode) =>
      v1(ApiMicroservices.staff, 'staff/my-profile/$staffCode/pin');

  /// Resolve staff code by user/org/school — same as web: **`GET /api/v1/staff/staff/code`**.
  static String get staffCodeByUser =>
      v1(ApiMicroservices.staff, 'staff/code');
  static String get staffDocuments =>
      v1(ApiMicroservices.staff, 'staff-documents');
  static String get staffDocumentAdd => staffDocuments;
  static String get staffDocumentUpdate => staffDocuments;
  static String get staffDates => v1(ApiMicroservices.staff, 'staff-dates');
  static String get staffAddress =>
      v1(ApiMicroservices.staff, 'staff-address');
  static String get staffSchedules =>
      v1(ApiMicroservices.staff, 'staff-schedules');

  // —— School users (user MS) ——
  static String get schoolUsers => v1(ApiMicroservices.user, 'school-users');
  static String get schoolUsersStaff =>
      v1(ApiMicroservices.user, 'school-users/staff');
  static String get schoolUsersDeactivate =>
      v1(ApiMicroservices.user, 'school-users/deactivate');
  static String get schoolUsersActivate =>
      v1(ApiMicroservices.user, 'school-users/activate');

  // —— Student MS ——
  static String get studentList => v1(ApiMicroservices.student);
  static String get studentClassroom =>
      v1(ApiMicroservices.student, 'student-classroom');
  static String get studentClassroomAssignStudent =>
      v1(ApiMicroservices.student, 'student-classroom/assign-student');
  static String get studentDocuments =>
      v1(ApiMicroservices.student, 'student-documents');
  static String studentProfile(String code) => '$studentList/$code';
  static String studentProfileUpdate(String code) =>
      '$studentList/$code/profile';
  /// Regular schedules for students (school-wide endpoint).
  static String get studentRegularSchedules =>
      v1(ApiMicroservices.student, 'regular-schedules');
  static String studentAddress(String code) => '$studentList/$code/address';
  static String studentSiblings(String code) => '$studentList/$code/siblings';
  static String get studentTags =>
      v1(ApiMicroservices.student, 'student-tags');
  static String studentDeactivate(String code) =>
      '$studentList/$code/deactivate';
  static String studentReactivate(String code) =>
      '$studentList/$code/reactivate';
  static String studentImportantDates(String code) =>
      '$studentList/$code/important-dates';
  static String studentHealth(String code) => '$studentList/$code/health';
  static String studentImmunization(String code) =>
      '$studentList/$code/immunization';
  static String studentImmunizationRecord(
          String studentCode, String recordCode) =>
      '$studentList/$studentCode/immunization/$recordCode';
  static String studentPhysicalExams(String code) =>
      '$studentList/$code/physical-exam';
  static String studentPhysicalExam(String studentCode, String examCode) =>
      '$studentList/$studentCode/physical-exam/$examCode';

  // —— User MS (shared) ——
  static String get physicians => v1(ApiMicroservices.user, 'physicians');
  static String get guardianUser =>
      v1(ApiMicroservices.user, 'guardian-user');
  static String get guardian => v1(ApiMicroservices.user, 'guardian');
  static String get guardianExisting =>
      v1(ApiMicroservices.user, 'guardian/existing');
  static String get tags => v1(ApiMicroservices.user, 'tags');
  static String get pickup => v1(ApiMicroservices.user, 'pickup');

  // —— Attendance MS ——
  static String get studentAttendanceDailyView =>
      v1(ApiMicroservices.attendance, 'student-attendance/view/daily');
  static String get studentAttendanceCustomView =>
      v1(ApiMicroservices.attendance, 'student-attendance/view/custom');
  static String get studentAttendanceAbsentView =>
      v1(ApiMicroservices.attendance, 'student-attendance/view/absent');
  static String get studentAttendanceAbsentToggleView =>
      v1(ApiMicroservices.attendance, 'student-attendance/view/absent/toggle');
  static String get studentAttendanceProfile =>
      v1(ApiMicroservices.attendance, 'student-attendance/profile');
  static String get studentAttendanceSignInFormList =>
      v1(ApiMicroservices.attendance, 'student-attendance/sign-in/form/list');
  static String get studentAttendanceSignOutFormList =>
      v1(ApiMicroservices.attendance, 'student-attendance/sign-out/form/list');
  static String get studentAttendanceAbsentFormList =>
      v1(ApiMicroservices.attendance, 'student-attendance/absent/form/list');
  static String get studentAttendanceTransferFormList =>
      v1(ApiMicroservices.attendance, 'student-attendance/transfer/form/list');
  static String studentAttendanceRecord(String attendanceRecordCode) =>
      v1(ApiMicroservices.attendance, 'student-attendance/$attendanceRecordCode');
  static String get studentAbsenceRecordsMarkAbsent =>
      v1(ApiMicroservices.attendance, 'student-absence-records/mark-absent');
  static String get staffAttendanceDailyView =>
      v1(ApiMicroservices.attendance, 'staff-attendance/view/daily');
  static String get staffAttendanceSignInFormList =>
      v1(ApiMicroservices.attendance, 'staff-attendance/sign-in/form/list');
  static String get staffAttendanceSignOutFormList =>
      v1(ApiMicroservices.attendance, 'staff-attendance/sign-out/form/list');
  static String get staffAttendanceTransferFormList =>
      v1(ApiMicroservices.attendance, 'staff-attendance/transfer/form/list');
  static String get staffAttendanceProfile =>
      v1(ApiMicroservices.attendance, 'staff-attendance/profile');
  static String get staffAttendanceAbsentView =>
      v1(ApiMicroservices.attendance, 'staff-attendance/view/absent');
  static String get staffAttendanceCustomView =>
      v1(ApiMicroservices.attendance, 'staff-attendance/view/custom');

  // —— Classroom MS ——
  /// Active classrooms — UAT: **`/api/v1/classroom/classroom/all`** (double `classroom`,
  /// same idea as `staff/staff/…` on the staff MS). Not `…/staff/all` (breaks gateway).
  static String get classroomAll =>
      v1(ApiMicroservices.classroom, 'classroom/all');

  // —— Activity MS ——
  static String get classroomActivitySettingsRoot =>
      v1(ApiMicroservices.activity, 'classrooms');
  static String get activities => v1(ApiMicroservices.activity, 'activities');
  static String get activityTypesRoot =>
      v1(ApiMicroservices.activity, 'activity-types');
}
