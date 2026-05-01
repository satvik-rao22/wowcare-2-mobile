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
        return ApiMicroservices.organization;
      case 'staff':
      case 'staff-classrooms':
      case 'staff-documents':
      case 'staff-dates':
      case 'staff-address':
      case 'staff-schedules':
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
        return ApiMicroservices.communication;
      default:
        return ApiMicroservices.user;
    }
  }

  /// Full URL: host from [ApiConstants.baseUrlForMicroservice] + [path].
  static String url(String path) {
    if (ApiConstants.isUat) return ApiPathsUat.url(path);
    final p = path.startsWith('/') ? path : '/$path';
    final ms = microserviceKeyFromPath(p);
    return '${ApiConstants.baseUrlForMicroservice(ms)}$p';
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

  /// GET /api/v1/school/{schoolCode}/regular-schedule
  static String schoolRegularSchedule(String schoolCode) =>
      '/api/v1/school/$schoolCode/regular-schedule';

  /// School entity root (gateway: school host).
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
  static const String staffDates = '/api/v1/staff-dates';
  static const String staffAddress = '/api/v1/staff-address';

  static String staffAllowedClassroomsByStaffCodePath(String staffCode) =>
      '$staffClassrooms/$staffCode/allowed-classrooms';

  static String staffPrimaryClassroomByStaffCodePath(String staffCode) =>
      '$staffClassrooms/$staffCode/primary-classroom';

  static const String staffSchedules = '/api/v1/staff-schedules';

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

  /// UAT/backend route: `PUT /api/v1/student/student/{studentCode}/siblings`
  static String studentSiblings(String code) =>
      '$studentList/student/$code/siblings';
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
  static const String futureAvailability = '/api/v1/future-availability';
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
  static const String staffAttendanceRecordsTransfer =
      '/api/v1/staff-attendance-records/transfer';

  // —— Classroom MS ([ApiConstants.classroomBaseUrl], devtunnel **8087**) ——
  /// `GET /api/v1/classroom/all`
  static const String classroomAll = '/api/v1/classroom/all';
  static String classroomByCode(String code) => '/api/v1/classroom/$code';
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

  // —— Document host (base path returned by upload-session response) ——

  static const String documentUploadSessionsRoot = '/api/v1/upload-sessions';

  static String documentAssetPresignPath({
    required String documentApiBasePath,
    required String sessionCode,
  }) {
    var base = documentApiBasePath.trim();
    if (base.isEmpty) base = '/api/v1';
    if (!base.startsWith('/')) base = '/$base';
    // If backend returns `/document-ms/api/v1`, strip the `/document-ms` prefix
    // because [ApiConstants.documentMsBaseUrl] already includes it in LOCAL.
    if (base.startsWith('/document-ms/')) {
      base = base.replaceFirst('/document-ms', '');
      if (base.isEmpty) base = '/api/v1';
    }
    base = base.replaceAll(RegExp(r'/+$'), '');
    return '$base/upload-sessions/$sessionCode/assets/presign/batch';
  }

  static String documentAssetCompletePath({
    required String documentApiBasePath,
    required String sessionCode,
    required String assetCode,
  }) {
    var base = documentApiBasePath.trim();
    if (base.isEmpty) base = '/api/v1';
    if (!base.startsWith('/')) base = '/$base';
    // If backend returns `/document-ms/api/v1`, strip the `/document-ms` prefix
    // because [ApiConstants.documentMsBaseUrl] already includes it in LOCAL.
    if (base.startsWith('/document-ms/')) {
      base = base.replaceFirst('/document-ms', '');
      if (base.isEmpty) base = '/api/v1';
    }
    base = base.replaceAll(RegExp(r'/+$'), '');
    final s = sessionCode.trim();
    final a = assetCode.trim();
    return '$base/upload-sessions/$s/assets/$a/complete';
  }

  static String documentUploadSessionPath(String sessionCode) =>
      '$documentUploadSessionsRoot/$sessionCode';
  static String documentMediaAssetByCodePath(String assetCode) =>
      '/api/v1/media-assets/${Uri.encodeComponent(assetCode.trim())}';

  static const String messagingCreateMessage = '/api/v1/conversations';
  static String messagingMessages(String conversationCode) =>
      '/api/v1/messages/conversation/$conversationCode';
}
