import 'api_constants.dart';

/// All REST paths use `/api/v1/{microservice}/…` where [microservice] matches
/// [ApiMicroservices]. Use [url] / [urlWithBase] to attach the correct host from
/// [ApiConstants.baseUrlForMicroservice] — no per-call base selection elsewhere.
class ApiPaths {
  ApiPaths._();

  /// `/api/v1/{ms}` or `/api/v1/{ms}/{tail}`.
  static String v1(String microservice, [String tail = '']) {
    if (tail.isEmpty) return '/api/v1/$microservice';
    final t = tail.startsWith('/') ? tail.substring(1) : tail;
    return '/api/v1/$microservice/$t';
  }

  /// Returns the microservice key from [path] (`/api/v1/{key}/…`), or [user].
  static String microserviceKeyFromPath(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    final parts = p.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length >= 3 && parts[0] == 'api' && parts[1] == 'v1') {
      return parts[2];
    }
    return ApiMicroservices.user;
  }

  /// Full URL: host from [ApiConstants.baseUrlForMicroservice] + [path].
  static String url(String path) {
    final p = path.startsWith('/') ? path : '/$path';
    final ms = microserviceKeyFromPath(p);
    return '${ApiConstants.baseUrlForMicroservice(ms)}$p';
  }

  /// Same as [url]; the [baseUrl] argument is ignored (kept so existing call sites
  /// keep compiling — routing is driven only by `/api/v1/{ms}/` in [path]).
  static String urlWithBase(String path, String baseUrl) => url(path);

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
  // UAT staff count endpoint is `/api/v1/staff/count` (single `staff` segment).
  static String get staffCount => v1(ApiMicroservices.staff, 'count');
  static String get staffProfile => staffList;
  /// Legacy single-segment path; prefer [staffProfilePath] / [staffMyProfilePinPath] for UAT.
  static String get staffMyProfile =>
      v1(ApiMicroservices.staff, 'my-profile');

  /// GET/PATCH staff profile (my-profile) — **`/api/v1/staff/my-profile/{staffCode}`**
  /// For logged-in user's own profile.
  static String staffProfilePath(String staffCode) =>
      v1(ApiMicroservices.staff, 'my-profile/$staffCode');

  /// GET staff profile (edit staff) — **`/api/v1/staff/{staffCode}/profile`**
  /// For viewing/editing another staff member's profile details.
  static String staffProfileByCodePath(String staffCode) =>
      // Microservice is already `staff` (so `/api/v1/staff/…` is added by [v1]).
      // UAT expects only a single `staff` segment for this endpoint.
      v1(ApiMicroservices.staff, '$staffCode/profile');

  /// GET sign-in PIN — **`/api/v1/staff/my-profile/{staffCode}/pin`**.
  static String staffMyProfilePinPath(String staffCode) =>
      v1(ApiMicroservices.staff, 'my-profile/$staffCode/pin');

  /// Resolve staff code by user/org/school — same as web: **`GET /api/v1/staff/staff/code`**.
  static String get staffCodeByUser =>
      v1(ApiMicroservices.staff, 'staff/code');
  static String get staffDocuments =>
      v1(ApiMicroservices.staff, 'staff-documents');
  static String get staffDocumentAdd => staffDocuments;
  static String get staffDocumentUpdate => staffDocuments;
  static String get staffDates => v1(ApiMicroservices.staff, 'staff-dates');
  /// Staff address update (PATCH) — `PATCH /api/v1/staff/staff-address/{staffCode}`
  static String get staffAddress =>
      v1(ApiMicroservices.staff, 'staff-address');

  /// Staff classrooms update (PATCH)
  /// - `PATCH /api/v1/staff/staff-classrooms/{staffCode}/allowed-classrooms`
  static String staffAllowedClassroomsByStaffCodePath(String staffCode) =>
      v1(ApiMicroservices.staff, 'staff-classrooms/$staffCode/allowed-classrooms');

  /// Staff classrooms update (PATCH)
  /// - `PATCH /api/v1/staff/staff-classrooms/{staffCode}/primary-classroom`
  static String staffPrimaryClassroomByStaffCodePath(String staffCode) =>
      v1(ApiMicroservices.staff, 'staff-classrooms/$staffCode/primary-classroom');
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

  // —— Organization admins (user MS) ——
  /// UAT/web contract: `POST /api/v1/user/organization-admins/deactivate`
  /// with query params `userCode` and `organizationCode`.
  static String get organizationAdminsDeactivate =>
      v1(ApiMicroservices.user, 'organization-admins/deactivate');

  /// UAT/web contract: `POST /api/v1/user/organization-admins/activate`
  /// with query params `userCode` and `organizationCode`.
  static String get organizationAdminsActivate =>
      v1(ApiMicroservices.user, 'organization-admins/activate');

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
