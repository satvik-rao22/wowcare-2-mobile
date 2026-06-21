import 'api_constants.dart';
import 'api_paths_uat.dart';

// Legacy flat paths (no microservice segment) — kept for reference only; do not use.
// import 'api_constants.dart';
//
// class ApiPaths {
//   ApiPaths._();
//
//   // Auth
//   static const String authLogin = '/api/v1/auth/login';
//   static const String authLogout = '/api/v1/auth/logout';
//   static const String authForgotPassword = '/api/v1/auth/forgot-password';
//   static const String authLoginContext = '/api/v1/auth/login-context';
//
//   // Users
//   static const String userRoot = '/api/v1/users';

//   static String userEmailChange(String userCode) =>
//       '$userRoot/$userCode/email-change';
//
//   // School - {organizationCode} in path
//   static const String schoolNamesByOrg = '/api/v1/schools/names-by-org';
//   static String schoolNamesByOrgPath(String orgCode) =>
//       '$schoolNamesByOrg/$orgCode';
//   static const String organizationNames = '/api/v1/organizations/names';
//
//   // Schools
//   static const String schools = '/api/v1/schools';
//   static String schoolByCode(String schoolCode) => '$schools/$schoolCode';
//
//   // Staff
//   static const String staffList = '/api/v1/staff';
//   static const String staffCount = '/api/v1/staff/count';
//   static const String staffProfile = '/api/v1/staff';
//   static const String staffMyProfile = '/api/v1/staff/my-profile';
//   static const String staffCodeByUser = '/api/v1/staff/code';
//   static const String staffDocuments = '/api/v1/staff-documents';
//   static const String staffDocumentAdd = '/api/v1/staff-documents';
//   static const String staffDocumentUpdate = '/api/v1/staff-documents';
//   static const String staffDates = '/api/v1/staff-dates';
//   static const String staffAddress = '/api/v1/staff-address';
//   static const String staffSchedules = '/api/v1/staff-schedules';
//
//   // School Users
//   static const String schoolUsers = '/api/v1/school-users';
//   static const String schoolUsersStaff = '/api/v1/school-users/staff';
//   static const String schoolUsersDeactivate = '/api/v1/school-users/deactivate';
//   static const String schoolUsersActivate = '/api/v1/school-users/activate';
//
//   // Student
//   static const String studentList = '/api/v1/student';
//   static const String studentClassroom = '/api/v1/student-classroom';
//   static const String studentDocuments = '/api/v1/student-documents';
//   static String studentProfile(String code) => '/api/v1/student/$code';
//   static String studentProfileUpdate(String code) => '/api/v1/student/$code/profile';
//   static const String studentRegularSchedules = '/api/v1/regular-schedules';
//   static String studentAddress(String code) => '/api/v1/student/$code/address';
//   static String studentSiblings(String code) => '/api/v1/student/$code/siblings';
//   static const String studentTags = '/api/v1/student-tags';
//   static String studentDeactivate(String code) => '/api/v1/student/$code/deactivate';
//   static String studentReactivate(String code) => '/api/v1/student/$code/reactivate';
//   static String studentImportantDates(String code) =>
//       '/api/v1/student/$code/important-dates';
//   static String studentHealth(String code) => '/api/v1/student/$code/health';
//   static String studentImmunization(String code) =>
//       '/api/v1/student/$code/immunization';
//   static String studentImmunizationRecord(String studentCode, String recordCode) =>
//       '/api/v1/student/$studentCode/immunization/$recordCode';
//   static String studentPhysicalExams(String code) =>
//       '/api/v1/student/$code/physical-exam';
//   static String studentPhysicalExam(String studentCode, String examCode) =>
//       '/api/v1/student/$studentCode/physical-exam/$examCode';
//
//   // Physicians
//   static const String physicians = '/api/v1/physicians';
//
//   // Guardian / Parent users
//   static const String guardianUser = '/api/v1/guardian-user';
//   static const String guardian = '/api/v1/guardian';
//   static const String guardianExisting = '/api/v1/guardian/existing';
//
//   // Tags
//   static const String tags = '/api/v1/tags';
//
//   // Attendance
//   static const String studentAttendanceDailyView = '/api/v1/student-attendance/view/daily';
//   static const String studentAttendanceCustomView = '/api/v1/student-attendance/view/custom';
//   static const String studentAttendanceAbsentView = '/api/v1/student-attendance/view/absent';
//   static const String studentAttendanceAbsentToggleView =
//       '/api/v1/student-attendance/view/absent/toggle';
//   static const String studentAttendanceProfile = '/api/v1/student-attendance/profile';
//   static const String studentAttendanceSignInFormList =
//       '/api/v1/student-attendance/sign-in/form/list';
//   static const String studentAttendanceSignOutFormList =
//       '/api/v1/student-attendance/sign-out/form/list';
//   static const String studentAttendanceAbsentFormList =
//       '/api/v1/student-attendance/absent/form/list';
//   static const String studentAttendanceTransferFormList =
//       '/api/v1/student-attendance/transfer/form/list';
//   static const String studentAbsenceRecordsMarkAbsent =
//       '/api/v1/student-absence-records/mark-absent';
//   static const String staffAttendanceDailyView = '/api/v1/staff-attendance/view/daily';
//   static const String staffAttendanceSignInFormList =
//       '/api/v1/staff-attendance/sign-in/form/list';
//   static const String staffAttendanceSignOutFormList =
//       '/api/v1/staff-attendance/sign-out/form/list';
//   static const String staffAttendanceTransferFormList =
//       '/api/v1/staff-attendance/transfer/form/list';
//   static const String staffAttendanceProfile = '/api/v1/staff-attendance/profile';
//   static const String staffAttendanceAbsentView = '/api/v1/staff-attendance/view/absent';
//   static const String staffAttendanceCustomView = '/api/v1/staff-attendance/view/custom';
//
//   // Classroom
//   static const String classroomAll = '/api/v1/classroom/all';
//   static const String classroomActivitySettingsRoot = '/api/v1/classrooms';
//
//   // Activities
//   static const String activities = '/api/v1/activities';
//
//   // Pickup
//   static const String pickup = '/api/v1/pickup';
//
//   static String url(String path) => '${ApiConstants.baseUrl}$path';
//   static String urlWithBase(String path, String baseUrl) => '$baseUrl$path';
// }

/// REST paths are `/api/v1/…` **without** a microservice segment in the path; the host
/// is chosen from the first resource segment after `/api/v1/` (see [microserviceKeyFromPath]).
class ApiPaths {
  ApiPaths._();

  /// Whether [path] should include org+school headers:
  /// `X-Organization-Code` and `X-School-Code`.
  ///
  /// Some endpoints (e.g. `GET /api/v1/student-classroom`) require these headers.
  static bool requiresOrganizationAndSchoolHeaders(String path) {
    if (ApiConstants.isUat) {
      return ApiPathsUat.requiresOrganizationAndSchoolHeaders(path);
    }
    final p = path.startsWith('/') ? path : '/$path';
    if (!p.startsWith('/api/v1/')) return false;

    // Public endpoints: no org/school context.
    if (p.startsWith(authLogin) || p.startsWith(authForgotPassword)) {
      return false;
    }

    // Document MS is namespaced separately.
    if (p.startsWith('/document-ms/')) return false;

    return true;
  }

  /// Maps [path] to [ApiMicroservices] for [ApiConstants.baseUrlForMicroservice].
  /// Paths do not include the MS name in the URL.
  static String microserviceKeyFromPath(String path) {
    if (ApiConstants.isUat) return ApiPathsUat.microserviceKeyFromPath(path);
    final p = path.startsWith('/') ? path : '/$path';
    final parts = p.split('/').where((s) => s.isNotEmpty).toList();
    if (parts.length < 3 || parts[0] != 'api') {
      return ApiMicroservices.user;
    }
    final version = parts[1];
    if (version != 'v1' && version != 'v2') {
      return ApiMicroservices.user;
    }
    final seg = parts[2];
    final nextSeg = parts.length > 3 ? parts[3] : '';
    switch (seg) {
      case 'auth':
      case 'users':
      case 'school-users':
      case 'organization-admins':
      case 'physicians':
      case 'guardian-user':
        return ApiMicroservices.user;
      case 'schools':
      case 'organizations':
      case 'school':
      case 'organization':
        return ApiMicroservices.organization;
      case 'staff':
      case 'staff-classrooms':
      case 'staff-documents':
      case 'staff-dates':
      case 'staff-address':
      case 'staff-schedules':
      case 'staff-shifts':
        return ApiMicroservices.staff;
      case 'student':
      case 'student-classroom':
      case 'student-documents':
      case 'student-tags':
      case 'regular-schedules':
      case 'tags':
      case 'pickup':

      /// `GET/POST /api/v1/guardian/...` (student MS — devtunnel **8085**).
      case 'guardian':
        if (nextSeg == 'activities') {
          return ApiMicroservices.activity;
        }
        return ApiMicroservices.student;
      case 'student-attendance':
      case 'student-absence-records':
      case 'student-attendance-records':
      case 'staff-attendance':
      case 'staff-absence-records':
      case 'staff-attendance-records':
      case 'attendance':
        return ApiMicroservices.attendance;
      case 'classroom':
      case 'individual-movements':
      case 'future-availability':
        return ApiMicroservices.classroom;
      case 'classrooms':
      case 'activities':
      case 'shared-activities':
      case 'activity-types':
        return ApiMicroservices.activity;
      case 'admin':
        // v2 admin activity moderation endpoints, e.g.
        // /api/v2/admin/activities/{cardGroupCode}/approve|reject
        if (nextSeg == 'activities') {
          return ApiMicroservices.activity;
        }
        return ApiMicroservices.user;
      case 'conversations':
      case 'messages':
        return ApiMicroservices.communication;
      case 'newsletters':
        return ApiMicroservices.newsLatter;
      case 'notification':
        return ApiMicroservices.notification;
      case 'kiosk':
        return ApiMicroservices.attendance;
      case 'billing':
      case 'discount':
      case 'subsidy':
      case 'fee-structure':
      case 'other-fees':
      case 'invoices':
      case 'ledgers':
      case 'ledger-transactions':
      case 'school-forte-configs':
      case 'payment-gateway':
        return ApiMicroservices.billing;
      default:
        return ApiMicroservices.user;
    }
  }

  /// Full URL: host from [ApiConstants.baseUrlForMicroservice] + [path].
  static String url(String path) {
    if (ApiConstants.isUat) return ApiPathsUat.url(path);
    final p = path.startsWith('/') ? path : '/$path';
    final ms = microserviceKeyFromPath(p);
    final localPath = _stripLocalMsPrefix(p, ms);
    return '${ApiConstants.baseUrlForMicroservice(ms)}$localPath';
  }

  /// For LOCAL devtunnel builds the base URL already encodes the microservice
  /// context path (e.g. /attendance).  Strip the matching segment from the API
  /// path so it isn't duplicated.
  ///
  /// Example:
  ///   path = /api/v1/attendance/schools/{code}/…
  ///   base = https://tunnel-8083.devtunnels.ms/attendance
  ///   → strip "attendance/" from path → /api/v1/schools/{code}/…
  ///   → full URL = https://tunnel-8083.devtunnels.ms/attendance/api/v1/schools/{code}/…
  static String _stripLocalMsPrefix(String path, String ms) {
    const _msPrefixMap = <String, String>{
      ApiMicroservices.attendance: '/api/v1/attendance/',
      ApiMicroservices.activity: '/api/v1/activity/',
    };
    final prefix = _msPrefixMap[ms];
    if (prefix != null && path.startsWith(prefix)) {
      return '/api/v1/${path.substring(prefix.length)}';
    }
    return path;
  }

  /// Same as [url]; the [baseUrl] argument is ignored (kept for call-site compatibility).
  static String urlWithBase(String path, String baseUrl) =>
      ApiConstants.isUat ? ApiPathsUat.urlWithBase(path, baseUrl) : url(path);

  // —— Auth (user host) ——
  static const String authLogin = '/api/v1/auth/login';
  static const String authLogout = '/api/v1/auth/logout';
  static const String authForgotPassword = '/api/v1/auth/forgot-password';
  static const String authLoginContext = '/api/v1/auth/login-context';

  // —— Users ——
  static const String userRoot = '/api/v1/users';
  static const String userDetails = '/api/v1/users/details';
  static String userEmailChange(String userCode) =>
      '$userRoot/$userCode/email-change';

  // —— Organization / school host ——
  static const String schoolNamesByOrg = '/api/v1/schools/names-by-org';
  static String schoolNamesByOrgPath(String orgCode) =>
      '$schoolNamesByOrg/$orgCode';
  static const String organizationNames = '/api/v1/organizations/names';

  /// Legacy regular-schedule list (prefer [schoolByCode] + `childcareSchedule`).
  static String schoolRegularSchedule(String schoolCode) =>
      '/api/v1/school/$schoolCode/regular-schedule';

  /// School settings (`data.childcareSchedule`, timezone, address, …).
  /// UAT: `/api/v1/organization/schools/{schoolCode}`.
  static const String schools = '/api/v1/schools';
  static String schoolByCode(String schoolCode) => '$schools/$schoolCode';

  /// GET /api/v1/schools/{schoolCode}/timezone
  static String schoolTimezone(String schoolCode) =>
      '$schools/$schoolCode/timezone';

  // —— Staff host ——
  static const String staffList = '/api/v1/staff';
  static const String staffClassrooms = '/api/v1/staff-classrooms';
  static const String staffClassroomsAssignStaff =
      '/api/v1/staff-classrooms/assign-staff';
  static const String staffClassroomsManageStaffList =
      '/api/v1/staff-classrooms/manage-staff-list';
  static const String staffCount = '/api/v1/staff/count';
  static String get staffProfile => staffList;

  static const String staffMyProfile = '/api/v1/staff/my-profile';

  /// GET/PATCH my-profile — `/api/v1/staff/my-profile/{staffCode}`.
  static String staffProfilePath(String staffCode) =>
      '$staffMyProfile/$staffCode';

  /// POST `/api/v1/staff/my-profile/{staffCode}/profile-photo/upload-session`.
  static String staffProfilePhotoUploadSessionPath(String staffCode) =>
      '$staffMyProfile/$staffCode/profile-photo/upload-session';

  /// POST `/api/v1/staff/my-profile/{staffCode}/profile-photo/finalize`.
  static String staffProfilePhotoFinalizePath(String staffCode) =>
      '$staffMyProfile/$staffCode/profile-photo/finalize';

  /// GET `/api/v1/staff/my-profile/profile-photo/asset-codes`.
  static const String staffProfilePhotoAssetCodes =
      '$staffMyProfile/profile-photo/asset-codes';

  /// POST `/api/v1/staff/my-profile/delete-profile-photo/{staffCode}`.
  static String staffDeleteProfilePhotoPath(String staffCode) =>
      '$staffMyProfile/delete-profile-photo/$staffCode';

  /// GET/PATCH other staff profile — `/api/v1/staff/{staffCode}/profile`.
  static String staffProfileByCodePath(String staffCode) =>
      '/api/v1/staff/$staffCode/profile';

  /// GET sign-in PIN — `/api/v1/staff/my-profile/{staffCode}/pin`.
  static String staffMyProfilePinPath(String staffCode) =>
      '$staffMyProfile/$staffCode/pin';

  static const String staffCodeByUser = '/api/v1/staff/code';
  static const String staffDocuments = '/api/v1/staff-documents';
  static const String staffDocumentAdd = staffDocuments;
  static const String staffDocumentUpdate = staffDocuments;
  static const String staffDocumentExpirySummary =
      '/api/v1/staff-documents/expiry-summary';
  static const String staffDates = '/api/v1/staff-dates';
  static const String staffDatesPhysicalCheckupSummary =
      '/api/v1/staff-dates/physical-checkup-summary';
  static const String staffAddress = '/api/v1/staff-address';

  static String staffAllowedClassroomsByStaffCodePath(String staffCode) =>
      '$staffClassrooms/$staffCode/allowed-classrooms';

  static String staffPrimaryClassroomByStaffCodePath(String staffCode) =>
      '$staffClassrooms/$staffCode/primary-classroom';

  static const String staffSchedules = '/api/v1/staff-schedules';

  /// Staff MS — staff scheduling shifts (`GET` with query filters).
  static const String staffShifts = '/api/v1/staff-shifts';

  /// POST per-staff available / scheduled / unscheduled hours for a date range.
  static const String staffShiftHoursRange = '/api/v1/staff-shifts/hours/range';

  /// POST classroom ratio forecast for a single day.
  static const String staffShiftClassroomForecast =
      '/api/v1/staff-shifts/schedule/classroom/forecast';

  /// POST classroom ratio forecast across a date range.
  static const String staffShiftClassroomForecastRange =
      '/api/v1/staff-shifts/schedule/classroom/forecast/range';

  /// POST `/api/v1/staff-shifts/absent-days` — deletes shifts that fall on
  /// the supplied absent dates after a recurring shift series is created.
  static const String staffShiftsAbsentDays =
      '/api/v1/staff-shifts/absent-days';

  /// POST `/api/v1/staff-shifts/publish` — publishes draft shifts either for
  /// the whole roster ([publishAllStaff] = true) or a subset
  /// ([selectedStaffCodes]), and either all unpublished shifts going forward
  /// ([publishAll] = true) or up to [publishUntilDate].
  static const String staffShiftsPublish = '/api/v1/staff-shifts/publish';

  /// PUT `/api/v1/staff-shifts/{shiftCode}` — update one shift occurrence.
  static String staffShiftByCode(String shiftCode) =>
      '$staffShifts/${Uri.encodeComponent(shiftCode)}';

  /// PUT `/api/v1/staff-shifts/series/{seriesCode}` — update an entire
  /// recurring shift series.
  static String staffShiftSeriesByCode(String seriesCode) =>
      '$staffShifts/series/${Uri.encodeComponent(seriesCode)}';

  /// Builds a full URL on the staff microservice host.
  static String staffMicroserviceUrl(String path) =>
      urlWithBase(path, ApiConstants.staffBaseUrl);

  // —— School users (user host) ——
  static const String schoolUsers = '/api/v1/school-users';
  static const String schoolUsersStaff = '/api/v1/school-users/staff';
  static const String schoolUsersDeactivate = '/api/v1/school-users/deactivate';
  static const String schoolUsersActivate = '/api/v1/school-users/activate';

  // —— Organization admins (user host) ——
  static const String organizationAdminsDeactivate =
      '/api/v1/organization-admins/deactivate';
  static const String organizationAdminsActivate =
      '/api/v1/organization-admins/activate';

  // —— Student host ——
  static const String studentList = '/api/v1/student';
  static const String studentClassroom = '/api/v1/student-classroom';
  static const String studentClassroomAssignStudent =
      '/api/v1/student-classroom/assign-student';
  static const String studentDocuments = '/api/v1/student-documents';
  // `student-documents` is its own top-level route on the student MS; the extra
  // `student/` prefix is the UAT gateway segment (re-inserted by UAT), so writing
  // it here 404s in LOCAL ("No static resource"). Keep direct-MS form.
  static const String studentDocumentExpiryCount =
      '/api/v1/student-documents/expiry-count';
  // Direct-MS form (controller root `/api/v1/student`); UAT re-inserts the
  // gateway segment. The doubled `student/student` form 404s in LOCAL.
  static String studentPhysicalCheckupCount(String schoolCode) =>
      '/api/v1/student/physical-checkup-count/$schoolCode';
  static String studentProfile(String code) => '$studentList/$code';
  static String studentProfileUpdate(String code) =>
      '$studentList/$code/profile';
  static String studentProfilePhotoUploadSessionPath(String studentCode) =>
      '$studentList/$studentCode/profile-photo/upload-session';
  static String studentProfilePhotoFinalizePath(String studentCode) =>
      '$studentList/$studentCode/profile-photo/finalize';
  static const String studentProfilePhotoAssetCodes =
      '/api/v1/student/profile-photo/asset-codes';
  static const String studentRegularSchedules = '/api/v1/regular-schedules';
  static String studentAddress(String code) => '$studentList/$code/address';

  /// UAT/backend route: `PUT /api/v1/student/student/{studentCode}/siblings`.
  /// Direct-MS form here (`/api/v1/student/{code}/siblings`); UAT re-inserts the
  /// gateway `student` segment — the doubled form 404s in LOCAL.
  static String studentSiblings(String code) => '$studentList/$code/siblings';
  static const String studentTags = '/api/v1/student-tags';

  /// `POST /api/v1/student-tags/activity-filter` — student codes for tag-based activity filtering.
  static const String studentTagsActivityFilter =
      '/api/v1/student-tags/activity-filter';
  static String studentDeactivate(String code) =>
      '$studentList/$code/deactivate';
  static String studentReactivate(String code) =>
      '$studentList/$code/reactivate';
  static String studentDelete(String code) => '$studentList/$code';
  static String studentImportantDates(String code) =>
      '$studentList/$code/important-dates';
  static String studentHealth(String code) => '$studentList/$code/health';
  static String studentImmunization(String code) =>
      '$studentList/$code/immunization';
  static String studentImmunizationRecord(
    String studentCode,
    String recordCode,
  ) => '$studentList/$studentCode/immunization/$recordCode';
  static String studentPhysicalExams(String code) =>
      '$studentList/$code/physical-exam';
  static String studentPhysicalExam(String studentCode, String examCode) =>
      '$studentList/$studentCode/physical-exam/$examCode';

  /// Student MS — `GET /api/v1/tags` ([ApiConstants.studentBaseUrl], devtunnel **8085**).
  static const String tags = '/api/v1/tags';

  // —— User host ——
  static const String physicians = '/api/v1/physicians';
  static const String guardianUser = '/api/v1/guardian-user';
  static const String guardian = '/api/v1/guardian';
  static const String guardianChildren = '/api/v1/guardian/children';
  static const String guardianProfile = '/api/v1/guardian/profile';
  static const String guardianExisting = '/api/v1/guardian/existing';
  static String guardianProfilePhotoUploadSessionPath(String guardianCode) =>
      '$guardian/${Uri.encodeComponent(guardianCode.trim())}/profile-photo/upload-session';
  static String guardianProfilePhotoFinalizePath(String guardianCode) =>
      '$guardian/${Uri.encodeComponent(guardianCode.trim())}/profile-photo/finalize';
  static const String pickup = '/api/v1/pickup';
  static const String individualMovements = '/api/v1/individual-movements';
  static const String individualMovementsStatusCounts =
      '/api/v1/individual-movements/status-counts';
  static const String futureAvailability = '/api/v1/future-availability';
  static const String futureAvailabilityRecompute =
      '/api/v1/future-availability/recompute';
  static String individualMovementById(int id) =>
      '/api/v1/individual-movements/$id';
  static String individualMovementStatusById(int id) =>
      '/api/v1/individual-movements/$id/status';

  // —— Attendance host ——
  static const String studentAttendanceDailyView =
      '/api/v1/student-attendance/view/daily';
  static const String studentAttendanceCustomView =
      '/api/v1/student-attendance/view/custom';
  static const String studentAttendanceMarkActivityStudentList =
      '/api/v1/student-attendance/view/mark-activity/student-list';
  static const String studentAttendanceAbsentView =
      '/api/v1/student-attendance/view/absent';
  static const String studentAttendanceAbsentToggleView =
      '/api/v1/student-attendance/view/absent/toggle';
  static const String studentAttendanceAbsentRecordsActivityView =
      '/api/v1/student-attendance/view/absent/records/activity';

  static const String studentAttendanceProfile =
      '/api/v1/student-attendance/profile';
  static const String studentAttendanceProfileAbsentToggle =
      '/api/v1/student-attendance/profile/absent/toggle';
  static const String studentAttendanceSignInStatus =
      '/api/v1/student-attendance/sign-in/status';
  static const String studentAttendanceSignInStatusAtTime =
      '/api/v1/student-attendance/sign-in/status/at-time';
  static const String studentAttendanceExpectedSummaryCard =
      '/api/v1/student-attendance/expected/summary/card';

  static const String studentAttendanceSignInFormList =
      '/api/v1/student-attendance/sign-in/form/list';
  static const String studentAttendanceSignOutFormList =
      '/api/v1/student-attendance/sign-out/form/list';
  static const String studentAttendanceAbsentFormList =
      '/api/v1/student-attendance/absent/form/list';
  static const String studentAttendanceTransferFormList =
      '/api/v1/student-attendance/transfer/form/list';

  /// Single attendance record by code.
  static String studentAttendanceRecord(String attendanceRecordCode) =>
      '/api/v1/student-attendance/$attendanceRecordCode';

  /// DELETE (or fetch) a student attendance record by record code.
  static String studentAttendanceRecordByCode(String recordCode) =>
      '/api/v1/student-attendance-records/$recordCode';

  /// Daily-row mutation endpoint for student attendance.
  /// Backend expects the row `code` from daily-view list APIs.
  static String studentAttendanceDailyRecordByRowCode(String rowCode) =>
      '/api/v1/student-attendance-records/daily/$rowCode';

  static const String studentAbsenceRecordsMarkAbsent =
      '/api/v1/student-absence-records/mark-absent';

  /// DELETE a student absence record by record code (override sign-in).
  static String studentAbsenceRecordByCode(String absenceRecordCode) =>
      '/api/v1/student-absence-records/$absenceRecordCode';
  static const String studentAttendanceRecords =
      '/api/v1/student-attendance-records';
  static const String studentAttendanceRecordsSignIn =
      '/api/v1/student-attendance-records/sign-in';
  static const String studentAttendanceRecordsParentSignIn =
      '/api/v1/student-attendance-records/parent-sign-in';
  static const String studentAttendanceRecordsSignOut =
      '/api/v1/student-attendance-records/sign-out';
  static const String studentAttendanceRecordsParentSignOut =
      '/api/v1/student-attendance-records/parent-sign-out';
  static const String studentAttendanceRecordsTransfer =
      '/api/v1/student-attendance-records/transfer';
  static const String staffAttendanceDailyView =
      '/api/v1/staff-attendance/view/daily';
  static const String staffAttendanceExpectedSummaryCard =
      '/api/v1/staff-attendance/expected/summary/card';

  static const String staffAttendanceSignInFormList =
      '/api/v1/staff-attendance/sign-in/form/list';
  static const String staffAttendanceSignOutFormList =
      '/api/v1/staff-attendance/sign-out/form/list';
  static const String staffAttendanceTransferFormList =
      '/api/v1/staff-attendance/transfer/form/list';

  static const String staffAbsenceRecordsMarkAbsent =
      '/api/v1/staff-absence-records/mark-absent';
  static const String staffAttendanceSignInStatus =
      '/api/v1/staff-attendance/sign-in/status';
  static const String staffAttendanceSignInStatusAtTime =
      '/api/v1/staff-attendance/sign-in/status/at-time';
  static const String staffAttendanceProfile =
      '/api/v1/staff-attendance/profile';
  static const String staffAttendanceProfileAbsentToggle =
      '/api/v1/staff-attendance/profile/absent/toggle';
  static const String staffAttendanceAbsentView =
      '/api/v1/staff-attendance/view/absent';
  static const String staffAttendanceAbsentFormList =
      '/api/v1/staff-attendance/absent/form/list';
  static const String staffAttendanceAbsentToggleView =
      '/api/v1/staff-attendance/view/absent/toggle';

  static const String staffAttendanceCustomView =
      '/api/v1/staff-attendance/view/custom';
  static const String staffAttendanceRecords =
      '/api/v1/staff-attendance-records';
  static String staffAttendanceDailyRecordByRowCode(String rowCode) =>
      '/api/v1/staff-attendance-records/daily/$rowCode';

  static const String staffAttendanceRecordsSignIn =
      '/api/v1/staff-attendance-records/sign-in';
  static const String staffAttendanceRecordsSignInSelf =
      '/api/v1/staff-attendance-records/sign-in/self';
  static const String staffAttendanceRecordsSignOut =
      '/api/v1/staff-attendance-records/sign-out';
  static const String staffAttendanceRecordsSignOutSelf =
      '/api/v1/staff-attendance-records/sign-out/self';
  static const String staffAttendanceRecordsTransfer =
      '/api/v1/staff-attendance-records/transfer';

  /// GET /api/v1/attendance/schools/{schoolCode}/attendance-settings/qr-code/validate
  /// Validate QR code for a school's attendance settings.
  static String qrCodeValidate(String schoolCode) =>
      '/api/v1/attendance/schools/$schoolCode/attendance-settings/qr-code/validate';

  /// GET /api/v1/attendance/schools/{schoolCode}/attendance-settings/qr-code/active
  /// Get active QR code for a school's attendance settings.
  static String qrCodeActive(String schoolCode) =>
      '/api/v1/attendance/schools/$schoolCode/attendance-settings/qr-code/active';

  /// GET /api/v1/attendance/schools/{schoolCode}/attendance-settings
  /// Single source of truth for GPS sign-in toggle, geofence radius, and
  /// auto sign-out settings.
  static String attendanceSettings(String schoolCode) =>
      '/api/v1/attendance/schools/$schoolCode/attendance-settings';

  // —— Kiosk (attendance MS) ——
  /// POST /api/v1/kiosk/verify-pin — Verify PIN for guardian/staff access.
  static const String kioskVerifyPin = '/api/v1/kiosk/verify-pin';

  // —— Reports (multiple microservices) ——
  /// POST /api/v1/attendance/student-attendance/reports/generate — Generate student attendance reports.
  static const String studentAttendanceReportsGenerate =
      '/api/v1/attendance/student-attendance/reports/generate';

  /// GET /api/v1/attendance/student-attendance/reports/recent — Get recent student attendance reports.
  static const String studentAttendanceReportsRecent =
      '/api/v1/attendance/student-attendance/reports/recent';

  /// POST /api/v1/attendance/staff-attendance/reports/generate — Generate staff attendance reports.
  static const String staffAttendanceReportsGenerate =
      '/api/v1/attendance/staff-attendance/reports/generate';

  /// GET /api/v1/attendance/staff-attendance/reports/recent — Get recent staff attendance reports.
  static const String staffAttendanceReportsRecent =
      '/api/v1/attendance/staff-attendance/reports/recent';

  /// POST /api/v1/staff/reports/generate — Generate staff directory reports (staff MS).
  static const String staffReportsGenerate = '/api/v1/staff/reports/generate';

  /// GET /api/v1/staff/reports/recent — Get recent staff directory reports (staff MS).
  static const String staffReportsRecent = '/api/v1/staff/reports/recent';

  /// POST /api/v1/student/reports/generate — Generate student management reports (student MS).
  static const String studentManagementReportsGenerate =
      '/api/v1/student/reports/generate';

  /// GET /api/v1/student/reports/recent — Get recent student management reports (student MS).
  static const String studentManagementReportsRecent =
      '/api/v1/student/reports/recent';

  /// POST /api/v1/student/settings/immunization/report — Generate immunization reports (student MS).
  static const String studentImmunizationReport =
      '/api/v1/student/settings/immunization/report';

  // —— Classroom MS ([ApiConstants.classroomBaseUrl], devtunnel **8087**) ——
  /// `GET /api/v1/classroom/all`
  static const String classroomAll = '/api/v1/classroom/all';

  /// `GET /api/v1/classroom/classroom?schoolCode=&page=&size=&status=&type=&sort=`
  /// Paginated classroom list with ratio and capacity data.
  ///
  /// Direct-MS form: the classroom controller root is `/api/v1/classroom`. The
  /// UAT gateway segment (`…/classroom/classroom`) is re-inserted by
  /// [ApiPathsUat._ensureUatMicroserviceSegment]; writing the doubled form here
  /// breaks LOCAL (the MS is hit directly by port and has no `/classroom/classroom`).
  static const String classroomPaginated = '/api/v1/classroom';

  /// `GET /api/v1/attendance/student-attendance/expected/summary/card/by-classrooms`
  static const String studentAttendanceExpectedSummaryCardByClassrooms =
      '/api/v1/attendance/student-attendance/expected/summary/card/by-classrooms';

  /// `GET /api/v1/attendance/staff-attendance/expected/summary/card/by-classrooms`
  static const String staffAttendanceExpectedSummaryCardByClassrooms =
      '/api/v1/attendance/staff-attendance/expected/summary/card/by-classrooms';

  static String schoolCapacityAge(String schoolCode) =>
      '/api/v1/schools/$schoolCode/capacity-age';

  // Direct-MS form (controller root `/api/v1/classroom`); UAT re-inserts the
  // gateway segment. The doubled form 404s in LOCAL (hit by port directly).
  static const String classroomCount = '/api/v1/classroom/count';
  static const String classroomSchoolFte = '/api/v1/classroom/school-fte';
  static String classroomByCode(String code) => '/api/v1/classroom/$code';
  static const String classroomLogoAssetCodes =
      '/api/v1/classroom/classroom-logo/asset-codes';
  static String classroomLogoUploadSessionPath(String classroomCode) =>
      '/api/v1/classroom/${classroomCode.trim()}/logo/upload-session';
  static String classroomLogoFinalizePath(String classroomCode) =>
      '/api/v1/classroom/${classroomCode.trim()}/logo/finalize';
  static const String classroomActivitySettingsRoot = '/api/v1/classrooms';

  // —— Activity host ——
  static const String activities = '/api/v1/activities';
  static String activityNapStartStudents(String classroomCode) =>
      '/api/v1/activities/${classroomCode.trim()}/nap-start-students';
  static const String activitiesUploadSessions =
      '/api/v2/activities/upload-sessions';
  static const String activitiesFeedDaily = '/api/v2/activities/feed/daily';
  static const String activitiesFeedRange = '/api/v2/activities/feed/range';
  static const String activitiesFeedDailySearch =
      '/api/v2/activities/feed/daily/search';
  static const String activitiesFeedRangeSearch =
      '/api/v2/activities/feed/range/search';
  static const String guardianActivitiesFeedDaily =
      '/api/v2/guardian/activities/feed/daily';
  static const String guardianActivitiesFeedRange =
      '/api/v2/guardian/activities/feed/range';
  static const String guardianActivitiesFeedDailySearch =
      '/api/v2/guardian/activities/feed/daily/search';
  static const String guardianActivitiesFeedRangeSearch =
      '/api/v2/guardian/activities/feed/range/search';
  static String guardianAcknowledgeActivity(String cardGroupCode) =>
      '/api/v2/guardian/activities/${Uri.encodeComponent(cardGroupCode.trim())}/acknowledge';
  static String guardianParentSignatureActivity(String cardGroupCode) =>
      '/api/v2/guardian/activities/${Uri.encodeComponent(cardGroupCode.trim())}/parent-signature';
  static String adminApproveActivity(String cardGroupCode) =>
      '/api/v2/admin/activities/${Uri.encodeComponent(cardGroupCode.trim())}/approve';
  static String adminRejectActivity(String cardGroupCode) =>
      '/api/v2/admin/activities/${Uri.encodeComponent(cardGroupCode.trim())}/reject';
  static const String activityTypesRoot = '/api/v1/activity-types';
  static const String pendingIncidentCount =
      '/api/v2/activities/admin/activities/pending-incident-count';

  // —— Document host (base path returned by upload-session response) ——

  static String get documentUploadSessionsRoot => ApiConstants.isUat
      ? '/api/v1/document/upload-sessions'
      : '/api/v1/upload-sessions';

  static String documentAssetPresignPath({
    required String documentApiBasePath,
    required String sessionCode,
  }) {
    var base = documentApiBasePath.trim();
    final defaultDocumentBasePath = ApiConstants.isUat
        ? '/api/v1/document'
        : '/api/v1';
    if (base.isEmpty) base = defaultDocumentBasePath;
    if (!base.startsWith('/')) base = '/$base';
    // If backend returns `/document-ms/api/v1`, strip the `/document-ms` prefix
    // because [ApiConstants.documentMsBaseUrl] already includes it in LOCAL.
    if (base.startsWith('/document-ms/')) {
      base = base.replaceFirst('/document-ms', '');
      if (base.isEmpty) base = defaultDocumentBasePath;
    }
    // UAT: documentMsBaseUrl is the bare gateway host, so the document MS
    // namespace (`/api/v1/document`) must live in the path itself.
    if (ApiConstants.isUat && !base.startsWith('/api/v1/document')) {
      base = '/api/v1/document';
    }
    base = base.replaceAll(RegExp(r'/+$'), '');
    return '${base.isEmpty ? '' : base}/upload-sessions/$sessionCode/assets/presign/batch';
  }

  static String documentAssetCompletePath({
    required String documentApiBasePath,
    required String sessionCode,
    required String assetCode,
  }) {
    var base = documentApiBasePath.trim();
    final defaultDocumentBasePath = ApiConstants.isUat
        ? '/api/v1/document'
        : '/api/v1';
    if (base.isEmpty) base = defaultDocumentBasePath;
    if (!base.startsWith('/')) base = '/$base';
    // If backend returns `/document-ms/api/v1`, strip the `/document-ms` prefix
    // because [ApiConstants.documentMsBaseUrl] already includes it in LOCAL.
    if (base.startsWith('/document-ms/')) {
      base = base.replaceFirst('/document-ms', '');
      if (base.isEmpty) base = defaultDocumentBasePath;
    }
    // UAT: documentMsBaseUrl is the bare gateway host, so the document MS
    // namespace (`/api/v1/document`) must live in the path itself.
    if (ApiConstants.isUat && !base.startsWith('/api/v1/document')) {
      base = '/api/v1/document';
    }
    base = base.replaceAll(RegExp(r'/+$'), '');
    final s = sessionCode.trim();
    final a = assetCode.trim();
    return '${base.isEmpty ? '' : base}/upload-sessions/$s/assets/$a/complete';
  }

  static String documentUploadSessionPath(String sessionCode) =>
      '$documentUploadSessionsRoot/$sessionCode';
  static String documentMediaAssetByCodePath(String assetCode) =>
      ApiConstants.isUat
      ? '/api/v1/document/media-assets/${Uri.encodeComponent(assetCode.trim())}'
      : '/api/v1/media-assets/${Uri.encodeComponent(assetCode.trim())}';

  /// POST /api/v1/document/media-assets/resolve — Resolve media asset codes to download URLs.
  static const String documentMediaAssetsResolve =
      '/api/v1/document/media-assets/resolve';

  // ─── Messaging / Communication microservice ──────────────────────────────
  // Base resource roots (new backend — no /messaging/ prefix).
  static const String conversations = '/api/v1/conversations';
  static const String messages = '/api/v1/messages';

  // Keep old names as aliases so call sites that haven't been migrated yet
  // still compile — they now resolve to the correct paths.
  static const String messagingConversations = conversations;
  static const String messagingCreateMessage = conversations;
  static const String messagingMessages = messages;

  // ── Conversation sub-resources ────────────────────────────────────────────
  static String messagingConversation(String code) => '$conversations/$code';
  static String messagingConversationsByType(String type) =>
      '$conversations/type/$type';
  static String messagingConversationsByStudent(String studentCode) =>
      '$conversations/student/$studentCode';
  static String messagingConversationsByClassroom(String classroomCode) =>
      '$conversations/classroom/$classroomCode';
  static String messagingConversationParticipants(String code) =>
      '$conversations/$code/participants';
  // DELETE /api/v1/conversations/{code}/participants/{userCode}
  static String conversationParticipant(String code, String userCode) =>
      '$conversations/$code/participants/$userCode';
  static String messagingConversationPrivateMode(String code) =>
      '$conversations/$code/private-mode';
  // Mark-read moved to messages controller:
  // POST /api/v1/messages/conversation/{code}/receipts/read-all
  static String messagingConversationMarkRead(String code) =>
      '$messages/conversation/$code/receipts/read-all';

  // ── Message sub-resources ─────────────────────────────────────────────────
  static String messagingMessage(String code) => '$messages/$code';
  static String messagingMessageReactions(String code) =>
      '$messages/$code/reactions';
  static String messagingMessageReaction(String code, String emoji) =>
      '$messages/$code/reactions/${Uri.encodeComponent(emoji)}';
  // Per new contract: POST /api/v1/messages/{code}/receipts/read
  static String messagingMessageRead(String code) =>
      '$messages/$code/receipts/read';
  // GET messages for a conversation
  static String messagesForConversation(String conversationCode) =>
      '$messages/conversation/$conversationCode';

  // ── Unread ────────────────────────────────────────────────────────────────
  // GET /api/v1/messages/unread-summary  (replaces /messaging/unread/counts)
  static const String messagingUnreadCounts = '$messages/unread-summary';
  static const String messagesUnreadSummary = '$messages/unread-summary';
  static const String messagesUnreadPerConversation =
      '$messages/unread-per-conversation';
  static String messagesConversationUnreadCount(String conversationCode) =>
      '$messages/conversation/$conversationCode/unread-count';
  // static String studentnewsLatter = 'api/v1/newsletters/student/';
  static String studentNewslettersByStudentCode(String studentCode) =>
      '/api/v1/newsletters/student/${Uri.encodeComponent(studentCode.trim())}';

  /// GET /api/v1/newsletters/school/{schoolCode}
  static String newslettersBySchool(String schoolCode) =>
      '/api/v1/newsletters/school/${Uri.encodeComponent(schoolCode.trim())}';

  /// GET /api/v1/newsletters/{code}
  static String newsletterByCode(String code) =>
      '/api/v1/newsletters/${Uri.encodeComponent(code.trim())}';

  // —— Notification service (FCM + delivery logs) ——
  static const String notificationFcmRegister =
      '/api/v1/notification/fcm/register';
  static String notificationFcmToken(String fcmToken) =>
      '/api/v1/notification/fcm/token/${Uri.encodeComponent(fcmToken.trim())}';
  static String notificationFcmUser(String userCode) =>
      '/api/v1/notification/fcm/user/${Uri.encodeComponent(userCode.trim())}';
  static const String notificationLogs = '/api/v1/notification/logs';
  static String notificationLogRead(String code) =>
      '/api/v1/notification/logs/${Uri.encodeComponent(code.trim())}/read';
  static String notificationLogClick(String code) =>
      '/api/v1/notification/logs/${Uri.encodeComponent(code.trim())}/click';
  static const String notificationLogsReadAll =
      '/api/v1/notification/logs/read-all';

  /// GET/PATCH user notification preferences (in-app / push / email per
  /// notification definition). Notification MS.
  static const String notificationPreferences =
      '/api/v1/notification/preferences';

  // —— Billing MS ——
  static const String billingStatements = '/api/v1/billing/statements';
  static String billingStatementDownload(String code) =>
      '/api/v1/billing/statements/${Uri.encodeComponent(code.trim())}/download';
  static const String discounts = '/api/v1/discount';
  static const String subsidies = '/api/v1/subsidy';
  static const String feeStructures = '/api/v1/fee-structure';
  static const String otherFees = '/api/v1/other-fees';
  static const String invoices = '/api/v1/invoices';
  static const String invoicesOverview = '/api/v1/invoices/overview';
  static const String invoicesFamilySummary = '/api/v1/invoices/family-summary';
  static const String invoicesFamilyLedger = '/api/v1/invoices/family-ledger';
  static const String invoicePayments = '/api/v1/invoices/payments';
  static const String invoiceRefunds = '/api/v1/invoices/refunds';
  static const String invoiceCredits = '/api/v1/invoices/credits';

  /// Paginated invoice list for an organization. Note: same URL shape as
  /// [invoiceByCode] but a GET that returns a page — keep them distinct.
  static String invoicesByOrganization(String organizationCode) =>
      '/api/v1/invoices/${Uri.encodeComponent(organizationCode.trim())}';
  static String invoiceByCode(String code) =>
      '/api/v1/invoices/${Uri.encodeComponent(code.trim())}';

  /// Full invoice detail (incl. line items) for the edit form.
  static String invoiceDetailByCode(String code) =>
      '/api/v1/invoices/by-code/${Uri.encodeComponent(code.trim())}';
  static String invoiceCancel(String code) => '${invoiceByCode(code)}/cancel';
  static String invoiceIssue(String code) => '${invoiceByCode(code)}/issue';
  static String invoiceResend(String code) => '${invoiceByCode(code)}/resend';
  static String discountByCode(String code) =>
      '/api/v1/discount/${Uri.encodeComponent(code.trim())}';
  static String discountDeactivate(String code) =>
      '/api/v1/discount/${Uri.encodeComponent(code.trim())}/deactivate';
  static String discountReactivate(String code) =>
      '/api/v1/discount/${Uri.encodeComponent(code.trim())}/reactivate';

  static const String ledgers = '/api/v1/ledgers';
  static String ledgerByCode(String code) =>
      '/api/v1/ledgers/${Uri.encodeComponent(code.trim())}';
  static String ledgerDeactivate(String code) =>
      '/api/v1/ledgers/${Uri.encodeComponent(code.trim())}/deactivate';
  static String ledgerReactivate(String code) =>
      '/api/v1/ledgers/${Uri.encodeComponent(code.trim())}/reactivate';

  static String ledgerEntries(String code) =>
      '/api/v1/ledgers/${Uri.encodeComponent(code.trim())}/entries';

  // —— Ledger Transactions (Billing MS) ——
  static const String ledgerTransactions = '/api/v1/ledger-transactions';

  // —— Auto Pay / Forte payment methods (Billing MS) ——
  /// School-level Forte config (returns `apiLoginId`).
  static const String schoolForteConfigs = '/api/v1/school-forte-configs';

  /// Whether auto-pay is enabled for a guardian.
  static const String autopayStatus =
      '/api/v1/payment-gateway/autopay/status';

  /// List/create saved payment methods (up to 4 per guardian).
  static const String paymentGatewayMethods =
      '/api/v1/payment-gateway/payment-methods';

  /// A single saved payment method (used for DELETE).
  static String paymentGatewayMethodByCode(String paymentMethodCode) =>
      '/api/v1/payment-gateway/payment-methods/'
      '${Uri.encodeComponent(paymentMethodCode.trim())}';

  /// Mark a saved payment method as primary (the default payment method).
  static String paymentGatewayMethodPrimary(String paymentMethodCode) =>
      '/api/v1/payment-gateway/payment-methods/'
      '${Uri.encodeComponent(paymentMethodCode.trim())}/primary';

  /// Mark a saved payment method as the auto-pay method.
  static String paymentGatewayMethodAutopay(String paymentMethodCode) =>
      '/api/v1/payment-gateway/payment-methods/'
      '${Uri.encodeComponent(paymentMethodCode.trim())}/autopay';
}
