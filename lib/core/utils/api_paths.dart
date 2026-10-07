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
    if (ApiConstants.isGatewayEnv) {
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
    if (ApiConstants.isGatewayEnv)
      return ApiPathsUat.microserviceKeyFromPath(path);
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
      case 'staff-overtime-records':
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
      case 'messaging':
      case 'conversations':
      case 'messages':
      case 'firebase':
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
      case 'payment':
        return ApiMicroservices.billing;
      case 'reports':
        // Billing reports live on the accounts (billing) MS: /api/v1/reports/billing/...
        return nextSeg == 'billing'
            ? ApiMicroservices.billing
            : ApiMicroservices.user;
      // Scheduler/Events-Todo MS — Events, Tasks & School Calendar.
      // event_remote_datasource.dart et al. call [urlWithBase] with
      // ApiConstants.eventsTodoBaseUrl as the (LOCAL/gateway-env-only)
      // `baseUrl` argument, but [urlWithBase] ignores it outside gateway envs
      // and defers to [url], which resolves the host from this map — so
      // these paths need an entry here too, or they silently fall through to
      // the `user` MS default.
      case 'events':
      case 'holidays':
      case 'occurrences':
      case 'calendar':
      case 'tasks':
        return ApiMicroservices.eventsTodo;
      default:
        return ApiMicroservices.user;
    }
  }

  /// Full URL: host from [ApiConstants.baseUrlForMicroservice] + [path].
  static String url(String path) {
    if (ApiConstants.isGatewayEnv) return ApiPathsUat.url(path);
    final p = path.startsWith('/') ? path : '/$path';
    final ms = microserviceKeyFromPath(p);
    final localPath = ms == ApiMicroservices.communication
        ? _ensureLocalCommunicationSegment(p)
        : _stripLocalMsPrefix(p, ms);
    return '${ApiConstants.baseUrlForMicroservice(ms)}$localPath';
  }

  /// LOCAL communication/messaging traffic goes through the shared gateway
  /// tunnel (devtunnel:gatewayPort, or ngrok when unset — see
  /// [ApiConstants.communicationBaseUrl]), which — like the UAT gateway —
  /// disambiguates by a `/messaging/` path segment rather than by a
  /// dedicated port. Without this, `/api/v1/firebase/token` (and
  /// conversations/messages) land on the gateway with no matching route and
  /// 500 with "No static resource ...". Mirrors
  /// [ApiPathsUat._ensureUatMicroserviceSegment]'s identical fix for the
  /// exact same symptom.
  static String _ensureLocalCommunicationSegment(String path) {
    if (path == '/api/v1/firebase/token') {
      return '/api/v1/messaging/firebase/token';
    }
    if (path.startsWith('/api/v1/messaging/')) return path;
    if (path.startsWith('/api/v1/conversations')) {
      return path.replaceFirst(
        '/api/v1/conversations',
        '/api/v1/messaging/conversations',
      );
    }
    if (path.startsWith('/api/v1/messages')) {
      return path.replaceFirst(
        '/api/v1/messages',
        '/api/v1/messaging/messages',
      );
    }
    return path;
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
      ApiConstants.isGatewayEnv
      ? ApiPathsUat.urlWithBase(path, baseUrl)
      : url(path);

  // —— Auth (user host) ——
  static const String authLogin = '/api/v1/auth/login';
  static const String authLogout = '/api/v1/auth/logout';
  static const String authForgotPassword = '/api/v1/auth/forgot-password';
  static const String authLoginContext = '/api/v1/auth/login-context';

  /// Authoritative server clock — `POST` with `{ "timeZone": "..." }`. Lives on
  /// the accounts/billing microservice (see [ServerTimeService]).
  static const String serverTime = '/api/v1/time';

  /// Access-token renewal. Mirrors the web client's
  /// `POST {gateway}/api/v1/user/auth/refresh` — the `auth` root maps to the
  /// `user` microservice (see [ApiPathsUat]), so this resolves to the same URL.
  static const String authRefresh = '/api/v1/auth/refresh';

  // —— Users ——
  static const String userRoot = '/api/v1/users';
  static const String userDetails = '/api/v1/users/details';
  static String userEmailChange(String userCode) =>
      '$userRoot/$userCode/email-change';

  /// Re-sends a guardian's app invitation email. Declared WITHOUT the leading
  /// `user` segment on purpose: `invitations` falls through to the `user`
  /// microservice by default, and [ApiPathsUat] prepends the segment itself —
  /// so this resolves to `{gateway}/api/v1/user/invitations/resend-invite-guardian`.
  /// Spelling it as `/api/v1/user/...` here would double it to `/user/user/...`.
  static const String resendInviteGuardian =
      '/api/v1/invitations/resend-invite-guardian';

  // —— Organization / school host ——
  /// GET /api/v1/organization/schools/names-by-org/{orgCode}?isAdmin=true|false
  ///
  /// Was `/api/v1/schools/names-by-org` — the bare, no-microservice-segment
  /// form, the same shape as the "Legacy flat paths ... do not use" block at
  /// the top of this file. Confirmed against the real backend trace for the
  /// switch-organization flow: `GET /api/v1/organization/schools/names-by-org/{org}`.
  static const String schoolNamesByOrg =
      '/api/v1/organization/schools/names-by-org';
  static String schoolNamesByOrgPath(String orgCode) =>
      '$schoolNamesByOrg/$orgCode';
  static const String organizationNames = '/api/v1/organizations/names';

  /// Legacy regular-schedule list (prefer [schoolByCode] + `childcareSchedule`).
  static String schoolRegularSchedule(String schoolCode) =>
      '/api/v1/school/$schoolCode/regular-schedule';

  /// School settings (`data.childcareSchedule`, timezone, address, …).
  /// Served by the organization microservice at
  /// `/api/v1/organization/schools/{schoolCode}`; the bare
  /// `/api/v1/schools/{code}` form is not exposed.
  static const String schools = '/api/v1/schools';
  static String schoolByCode(String schoolCode) =>
      '/api/v1/organization/schools/$schoolCode';

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

  /// PATCH work break reminder — `/api/v1/staff/staff/my-profile/{staffCode}/work-break-reminder`.
  static String staffWorkBreakReminderPath(String staffCode) =>
      '$staffMyProfile/$staffCode/work-break-reminder';

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

  /// POST `/api/v1/student/delete-profile-photo/{studentCode}` (empty `{}` body).
  ///
  /// Direct-MS form, like the sibling photo paths above; UAT re-inserts the
  /// gateway segment to reach the live route
  /// `/api/v1/student/student/delete-profile-photo/{studentCode}`. Writing that
  /// doubled form here would 404 in LOCAL — see the note on
  /// [studentPhysicalCheckupCount].
  static String studentDeleteProfilePhotoPath(String studentCode) =>
      '$studentList/delete-profile-photo/$studentCode';
  static const String studentRegularSchedules = '/api/v1/regular-schedules';
  static String studentAddress(String code) => '$studentList/$code/address';

  /// UAT/backend route: `PUT /api/v1/student/student/{studentCode}/siblings`.
  /// Direct-MS form here (`/api/v1/student/{code}/siblings`); UAT re-inserts the
  /// gateway `student` segment — the doubled form 404s in LOCAL.
  static String studentSiblings(String code) => '$studentList/$code/siblings';

  /// `POST /api/v1/student/{newStudentCode}/add-sibling` — links siblings onto a
  /// newly created student (used by the add-student dialog flow, not edit profile).
  static String studentAddSibling(String code) =>
      '$studentList/$code/add-sibling';
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

  /// School-level student settings (health/documents edit permissions).
  static const String studentSettings = '/api/v1/student-settings';

  /// GET /api/v1/student/settings/immunization?schoolCode={schoolCode}
  /// Available immunizations (vaccines) for a school.
  static const String studentImmunizationSettings =
      '/api/v1/student/settings/immunization';

  /// PATCH the logged-in guardian's own profile (resolves to
  /// `/api/v1/student/guardian/my-profile`). Identified by schoolCode+userCode
  /// query params, like [guardianProfile].
  static const String guardianMyProfile = '/api/v1/guardian/my-profile';
  static const String guardianExisting = '/api/v1/guardian/existing';
  static String guardianProfilePhotoUploadSessionPath(String guardianCode) =>
      '$guardian/${Uri.encodeComponent(guardianCode.trim())}/profile-photo/upload-session';
  static String guardianProfilePhotoFinalizePath(String guardianCode) =>
      '$guardian/${Uri.encodeComponent(guardianCode.trim())}/profile-photo/finalize';

  /// `POST /api/v1/guardian/{code}/change-pin/{pin}` — sets a guardian's clock
  /// PIN to an operator-supplied value (student MS).
  static String guardianChangePinPath(String guardianCode, String pin) =>
      '$guardian/${Uri.encodeComponent(guardianCode.trim())}'
      '/change-pin/${Uri.encodeComponent(pin.trim())}';

  /// `POST /api/v1/guardian/{code}/generate-pin` — server picks a new clock PIN.
  static String guardianGeneratePinPath(String guardianCode) =>
      '$guardian/${Uri.encodeComponent(guardianCode.trim())}/generate-pin';

  /// POST `/api/v1/guardian/delete-profile-photo/{guardianCode}` (empty `{}` body).
  ///
  /// `guardian` routes to the STUDENT microservice (see
  /// [microserviceKeyFromPath]), so UAT rewrites this to the live route
  /// `/api/v1/student/guardian/delete-profile-photo/{guardianCode}`. Takes the
  /// `GUA_*` guardian code, same as the upload paths above.
  static String guardianDeleteProfilePhotoPath(String guardianCode) =>
      '$guardian/delete-profile-photo/${Uri.encodeComponent(guardianCode.trim())}';
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

  /// DELETE a staff absence record by record code (admin override sign-in).
  static String staffAbsenceRecordByCode(String absenceRecordCode) =>
      '/api/v1/staff-absence-records/$absenceRecordCode';
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

  /// GET /api/v1/attendance/schools/{schoolCode}/attendance-settings/allow-teacher-cross-class-attendance
  /// Lightweight flag: whether teachers can sign in/out (and view) students
  /// from any classroom. When true, non-admin staff behave like an admin for
  /// student attendance.
  static String allowTeacherCrossClassAttendance(String schoolCode) =>
      '/api/v1/attendance/schools/$schoolCode/attendance-settings/allow-teacher-cross-class-attendance';

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

  /// POST /api/v1/student/student/reports/generate — Generate student incident reports.
  static const String studentIncidentReportsGenerate =
      '/api/v1/student/student/reports/generate';

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
      '/api/v1/student/reports/generate';

  // POST /api/v1/staff/staff-shifts/reports/generate - Generate Staff Scheduling reports (staff MS).
  static const String staffSchedulingReportsGenerate =
      '/api/v1/staff/staff-shifts/reports/generate';

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

  /// POST — creates a `SCHOOL_CLOUD` scoped upload session for direct image
  /// uploads to a school's cloud gallery (owner type `SCHOOL`).
  static String schoolCloudUploadSessionsPath(String schoolCode) =>
      '/api/v1/document/schools/${Uri.encodeComponent(schoolCode.trim())}/cloud/upload-sessions';

  static String get documentUploadSessionsRoot => ApiConstants.isGatewayEnv
      ? '/api/v1/document/upload-sessions'
      : '/api/v1/upload-sessions';

  static String documentAssetPresignPath({
    required String documentApiBasePath,
    required String sessionCode,
  }) {
    var base = documentApiBasePath.trim();
    final defaultDocumentBasePath = ApiConstants.isGatewayEnv
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
    if (ApiConstants.isGatewayEnv && !base.startsWith('/api/v1/document')) {
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
    final defaultDocumentBasePath = ApiConstants.isGatewayEnv
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
    if (ApiConstants.isGatewayEnv && !base.startsWith('/api/v1/document')) {
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
      ApiConstants.isGatewayEnv
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

  /// School-level messaging policy — GET
  /// /api/v1/messaging/communication-settings?schoolCode=... — controls
  /// whether admins can delete any message (not just their own) and the
  /// minutes a sender has to delete their own message after sending.
  static const String communicationSettings =
      '/api/v1/messaging/communication-settings';

  /// Server-side conversation search — GET /conversations/search?q=...&type=...
  /// Searches ALL of the account's conversations of [type] matching the
  /// query text, not just whatever page is already loaded client-side.
  static const String messagingConversationsSearch = '$conversations/search';

  // POST /api/v1/messages/conversations/{code}/attachments/upload-session
  // (resolves to .../messaging/messages/conversations/{code}/attachments/
  // upload-session in UAT, confirmed against the working web-app request) —
  // mirrors the student-documents/staff-documents upload-session bootstrap
  // so message attachments can use the same generic presign → S3 PUT →
  // complete flow.
  static String messagingConversationUploadSessionPath(String code) =>
      '$messages/conversations/$code/attachments/upload-session';

  // DELETE /api/v1/messages/attachments/{attachmentId} — removes a single
  // attachment (by the messaging-service attachment id, not the document
  // asset code) from its message without deleting the whole message.
  static String messagingAttachmentPath(int attachmentId) =>
      '$messages/attachments/$attachmentId';

  // POST /api/v1/messages/conversations/{code}/attachments — registers a
  // completed document-service asset against the conversation and returns
  // the messaging-service attachment id required by [messagingMessages]'s
  // `attachmentIds` (the asset code alone is not a valid send-message
  // reference — confirmed against the working web-app request for this
  // endpoint).
  static String messagingConversationAttachmentsPath(String code) =>
      '$messages/conversations/$code/attachments';

  // ── Conversation sub-resources ────────────────────────────────────────────
  static String messagingConversation(String code) => '$conversations/$code';
  static String messagingConversationsByType(String type) =>
      '$conversations/type/$type';
  static String messagingConversationsByStudent(String studentCode) =>
      '$conversations/student/$studentCode';
  static String messagingConversationsByClassroom(String classroomCode) =>
      '$conversations/classroom/$classroomCode';

  /// Get-or-create the classroom's CLASSROOM_CHAT and reconcile its staff roster.
  static String messagingClassroomReconcile(String classroomCode) =>
      '$conversations/classroom/$classroomCode/reconcile';

  /// Present-vs-missing staff roster for a classroom's Notes chat — `present`
  /// are currently-assigned staff/admins who should show in the participant
  /// chip row; `missing` are ones the conversation still lists but who are no
  /// longer on the classroom (must NOT be shown).
  static String messagingClassroomRosterStatus(String classroomCode) =>
      '$conversations/classroom/$classroomCode/roster-status';
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
  // POST /api/v1/messages/conversation/{code}/receipts/delivered-all — marks
  // every unread message in the conversation as delivered for the current
  // user, even with the thread closed, so the sender's ticks advance
  // promptly (mirrors the web app's markAllAsDelivered).
  static String messagingConversationMarkDelivered(String code) =>
      '$messages/conversation/$code/receipts/delivered-all';

  // ── Message sub-resources ─────────────────────────────────────────────────
  static String messagingMessage(String code) => '$messages/$code';
  static String messagingMessageReactions(String code) =>
      '$messages/$code/reactions';
  static String messagingMessageReaction(String code, String emoji) =>
      '$messages/$code/reactions/${Uri.encodeComponent(emoji)}';
  // Per new contract: POST /api/v1/messages/{code}/receipts/read
  static String messagingMessageRead(String code) =>
      '$messages/$code/receipts/read';
  // GET /api/v1/messaging/messages/{code}/receipts — full per-recipient-
  // per-persona receipt rows (userCode, userName, userRole/role,
  // deliveredAt, readAt). A dual-role account (e.g. staff who's also a
  // guardian) gets one row per persona here; the message list endpoint's
  // own embedded `receipts` field is a lighter shape that doesn't reliably
  // carry userName/role, so the Message Info dialog fetches this endpoint
  // directly instead of trusting the embedded data.
  static String messagingMessageReceipts(String code) =>
      '$messages/$code/receipts';
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

  // —— Scheduler MS — Events (Events, Tasks & School Calendar) ——
  /// `GET`/`POST` `/api/v1/events`. List supports
  /// `?type=&fromDate=&toDate=&name=&recurringFlag=&createdBy=&page=&size=`.
  static const String events = '/api/v1/events';

  /// `GET`/`PATCH`/`DELETE` `/api/v1/events/{code}`.
  static String eventByCode(String code) =>
      '$events/${Uri.encodeComponent(code.trim())}';

  /// `GET /api/v1/events/{code}/occurrences` — occurrence rows of a
  /// series; carries `myRsvp` when `X-Party-Code` is sent.
  static String eventOccurrences(String code) =>
      '${eventByCode(code)}/occurrences';

  /// `POST /api/v1/events/{code}/occurrences/{occ}/rsvp` — upsert RSVP.
  static String occurrenceRsvp(String code, String occurrenceCode) =>
      '${eventOccurrences(code)}/${Uri.encodeComponent(occurrenceCode.trim())}/rsvp';

  /// `GET /api/v1/events/{code}/occurrences/{occ}/rsvps` — roster grouped
  /// by party type (staffs/students/guardians) with counts.
  static String occurrenceRsvps(String code, String occurrenceCode) =>
      '${occurrenceRsvp(code, occurrenceCode)}s';

  /// `GET /api/v1/occurrences?fromDate=&toDate=&type=&classroomCode=&`
  /// `participantCode=&name=&status=&page=&size=&sort=` — the rich
  /// occurrence view (display fields + myRsvp + rsvpSummary +
  /// participants) that backs every read screen.
  static const String occurrencesView = '/api/v1/occurrences';

  /// `GET /api/v1/calendar/feed?fromDate=&toDate=&scope=&include=&...` —
  /// unified calendar feed of events + tasks + holidays.
  static const String calendarFeed = '/api/v1/calendar/feed';

  // —— Scheduler MS — Holidays (Events, Tasks & School Calendar) ——
  /// `GET`/`POST` `/api/v1/holidays`. List supports `?year=&type=&status=`.
  static const String holidays = '/api/v1/holidays';

  /// `PATCH`/`DELETE` `/api/v1/holidays/{code}`.
  static String holidayByCode(String code) =>
      '$holidays/${Uri.encodeComponent(code.trim())}';

  /// `PATCH` `/api/v1/holidays/{code}/status` — approve/reject a federal holiday.
  static String holidayStatus(String code) => '${holidayByCode(code)}/status';

  // —— Events/Todo MS — Tasks ——
  /// `GET`/`POST` `/api/v1/tasks`. List supports the series filters
  /// `?seriesStatus=&recurring=&q=&page=&size=`.
  static const String tasks = '/api/v1/tasks';

  /// `PATCH`/`DELETE` `/api/v1/tasks/{code}` (series-level).
  static String taskByCode(String code) =>
      '$tasks/${Uri.encodeComponent(code.trim())}';

  /// `DELETE` `/api/v1/tasks/{code}/assignees/{staffCode}` — remove one
  /// assignee from a task's roster without touching the series (§4a).
  /// Also `PATCH` — update one assignee's priority in isolation (§4b).
  static String taskAssignee(String code, String staffCode) =>
      '${taskByCode(code)}/assignees/${Uri.encodeComponent(staffCode.trim())}';

  /// `GET` `/api/v1/tasks/{code}/occurrences` — every occurrence of one series
  /// (§11a). The only endpoint that surfaces occurrence codes.
  static String taskOccurrences(String code) =>
      '${taskByCode(code)}/occurrences';

  /// `GET`/`PATCH`/`DELETE` `/api/v1/tasks/{code}/occurrences/{occurrenceCode}`
  /// — one occurrence's own detail / THIS_ONLY reschedule / cancel (§11b–d).
  static String taskOccurrence(String code, String occurrenceCode) =>
      '${taskOccurrences(code)}/${Uri.encodeComponent(occurrenceCode.trim())}';

  /// `GET` `/api/v1/tasks/assignments` — flat, mixed-status page of task
  /// assignments (same filters as the board, ungrouped).
  static const String taskAssignments = '$tasks/assignments';

  /// `GET`/`PATCH`/`DELETE` `/api/v1/tasks/assignments/{code}` — one specific
  /// assignment: fetch (§5a), edit its own occurrenceDate/startTime/dueDate/
  /// dueTime/priority (§5b), or remove one occurrence for one assignee (§5c).
  static String taskAssignmentByCode(String code) =>
      '$taskAssignments/${Uri.encodeComponent(code.trim())}';

  /// `GET` `/api/v1/tasks/board` — Kanban board grouped into status columns.
  static const String taskBoard = '$tasks/board';

  /// `PATCH` `/api/v1/tasks/assignments/{code}/status` — quick status change
  /// on a single assignment.
  static String taskAssignmentStatus(String code) =>
      '${taskAssignmentByCode(code)}/status';

  /// `POST` `/api/v1/tasks/upload-session` — open a shared upload session for
  /// task attachments (document-microservice, domain `TASK`).
  static const String taskUploadSession = '$tasks/upload-session';

  /// `GET` `/api/v1/tasks/{code}/attachments` — the series' current
  /// attachments. Mirrors the events-todo endpoint of the same shape
  /// (`GET /api/v1/events/{eventCode}/attachments`, `data.items[]`); the Tasks
  /// samples only document the write side (`assetCodes` on §1/§3c), so callers
  /// must tolerate a 404/405 from a backend that hasn't shipped it yet.
  static String taskAttachments(String code) => '${taskByCode(code)}/attachments';

  /// `DELETE` `/api/v1/tasks/{code}/attachments/{attachmentCode}` — detach one
  /// attachment by its **attachment** code (not the document asset code).
  static String taskAttachment(String code, String attachmentCode) =>
      '${taskAttachments(code)}/${Uri.encodeComponent(attachmentCode.trim())}';

  /// `POST` `/api/v1/events/upload-session` — open a shared upload session for
  /// event attachments (document-microservice, domain `EVENT`).
  ///
  /// Events and tasks are the same microservice (Events/Todo MS), so this
  /// mirrors [taskUploadSession] exactly: the owning service mints the session
  /// with its own domain/owner scoping, then the generic document-service
  /// presign → PUT → complete flow takes over.
  static const String eventUploadSession = '$events/upload-session';

  // —— Notification service (FCM + delivery logs) ——
  static const String notificationFcmRegister =
      '/api/v1/notification/fcm/register';
  static String notificationFcmToken(String fcmToken) =>
      '/api/v1/notification/fcm/token/${Uri.encodeComponent(fcmToken.trim())}';
  static String notificationFcmUser(String userCode) =>
      '/api/v1/notification/fcm/user/${Uri.encodeComponent(userCode.trim())}';
  // In-app notification inbox (the app-bar bell list). Replaces the old
  // `/notification/logs` endpoints. Notification MS.
  static const String notificationInbox = '/api/v1/notification/inbox';
  static String notificationInboxRead(String code) =>
      '/api/v1/notification/inbox/${Uri.encodeComponent(code.trim())}/read';
  static String notificationInboxClick(String code) =>
      '/api/v1/notification/inbox/${Uri.encodeComponent(code.trim())}/click';
  static const String notificationInboxReadAll =
      '/api/v1/notification/inbox/read-all';
  static const String notificationInboxUnreadCounts =
      '/api/v1/notification/inbox/unread-counts';

  /// GET/PATCH user notification preferences (in-app / push / email per
  /// notification definition). Notification MS.
  static const String notificationPreferences =
      '/api/v1/notification/preferences';

  /// GET/PATCH user notification preferences grouped by notification group
  /// (each group lists only the channels it supports; a channel missing from
  /// a group's `channels` means it isn't offered for that group). Notification MS.
  static const String notificationPreferenceGroups =
      '/api/v1/notification/preferences/groups';

  // —— Billing MS ——
  /// POST /api/v1/reports/billing/generate — generate a billing report (xlsx/pdf); returns the
  /// stored asset metadata so it downloads via the document service like the other reports.
  static const String billingReportGenerate =
      '/api/v1/reports/billing/generate';
  static const String billingTransactionReportGenerate =
      '/api/v1/reports/billing/TRANSACTION';
  static const String billingInvoiceReportGenerate =
      '/api/v1/reports/billing/INVOICE';
  static const String billingPaymentSummaryReportGenerate =
      '/api/v1/reports/billing/PAYMENT_SUMMARY';
  static const String billingOutstandingReportGenerate =
      '/api/v1/reports/billing/OUTSTANDING';
  static const String billingRefundReportGenerate =
      '/api/v1/reports/billing/REFUND';
  static const String billingStudentMappingReportGenerate =
      '/api/v1/reports/billing/STUDENT_BILLING_MAPPING';
  static const String billingStatements = '/api/v1/billing/statements';
  static String billingStatementDownload(String code) =>
      '/api/v1/billing/statements/${Uri.encodeComponent(code.trim())}/download';
  static const String discounts = '/api/v1/discount';
  static const String subsidies = '/api/v1/subsidy';
  static const String feeStructures = '/api/v1/fee-structure';
  static const String otherFees = '/api/v1/other-fees';
  static const String invoices = '/api/v1/invoices';
  static const String invoicesOverview = '/api/v1/invoices/overview';
  static const String invoicesAnalytics = '/api/v1/invoices/analytics';
  static const String invoicesTransactions = '/api/v1/invoices/transactions';
  static const String invoicesFamilySummary = '/api/v1/invoices/family-summary';
  static const String invoicesFamilyLedger = '/api/v1/invoices/family-ledger';
  static const String invoicesFamilyLedgerByGuardian =
      '/api/v1/invoices/family-ledger/by-guardian';
  static const String invoicePayments = '/api/v1/invoices/payments';
  static const String invoiceRefunds = '/api/v1/invoices/refunds';
  static const String invoiceCredits = '/api/v1/invoices/credits';

  /// `POST /api/v1/invoices/check-recipients?schoolCode={code}` — body is a
  /// raw JSON array of student codes. Checks whether each has a family/
  /// billing profile before an invoice can be created for them.
  static const String invoicesCheckRecipients =
      '/api/v1/invoices/check-recipients';

  /// Paginated invoice list for an organization. Note: same URL shape as
  /// [invoiceByCode] but a GET that returns a page — keep them distinct.
  static String invoicesByOrganization(String organizationCode) =>
      '/api/v1/invoices/${Uri.encodeComponent(organizationCode.trim())}';
  static String invoiceByCode(String code) =>
      '/api/v1/invoices/${Uri.encodeComponent(code.trim())}';

  /// Full invoice detail (incl. line items) for the edit form.
  static String invoiceDetailByCode(String code) =>
      '/api/v1/invoices/by-code/${Uri.encodeComponent(code.trim())}';

  /// Edit a draft invoice — `PATCH /api/v1/invoices/{invoiceCode}/draft`.
  static String invoiceDraft(String code) => '${invoiceByCode(code)}/draft';
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
  static const String schoolForteConfigs = '/api/v1/school-forte-configs/search';

  /// School payment settings — which method types are accepted and who pays the
  /// convenience fee. `GET /api/v1/payment/settings?schoolCode=...`.
  static const String paymentSettings = '/api/v1/payment/settings';

  /// Whether auto-pay is enabled for a guardian.
  static const String autopayStatus = '/api/v1/payment-gateway/autopay/status';

  /// List/create saved payment methods (up to 4 per guardian).
  static const String paymentGatewayMethods =
      '/api/v1/payment-gateway/payment-methods';

  /// Charge a guardian's saved payment method (Pay Now).
  static const String paymentGatewayGuardianPay =
      '/api/v1/payment-gateway/guardian/pay';

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
