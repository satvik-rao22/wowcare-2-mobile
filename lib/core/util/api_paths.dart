import 'api_constants.dart';

class ApiPaths {
  ApiPaths._();

  // Auth
  static const String authLogin = '/api/v1/auth/login';
  static const String authLogout = '/api/v1/auth/logout';
  static const String authForgotPassword = '/api/v1/auth/forgot-password';
  static const String authLoginContext = '/api/v1/auth/login-context';

  // Users
  static const String userRoot = '/api/v1/users';
  static String userEmailChange(String userCode) =>
      '$userRoot/$userCode/email-change';

  // School - {organizationCode} in path
  static const String schoolNamesByOrg = '/api/v1/schools/names-by-org';
  static String schoolNamesByOrgPath(String orgCode) =>
      '$schoolNamesByOrg/$orgCode';
  static const String organizationNames = '/api/v1/organizations/names';

  // Schools
  static const String schools = '/api/v1/schools';
  static String schoolByCode(String schoolCode) => '$schools/$schoolCode';

  // Staff
  static const String staffList = '/api/v1/staff';
  static const String staffClassrooms = '/api/v1/staff-classrooms';
  static const String staffClassroomsAssignStaff =
      '/api/v1/staff-classrooms/assign-staff';
  static const String staffCount = '/api/v1/staff/count';
  static const String staffProfile = '/api/v1/staff';
  /// My-profile controller: `PATCH /api/v1/staff/my-profile/{staffCode}`
  /// Used for updating the logged-in staff member's basic profile + address.
  static const String staffMyProfile = '/api/v1/staff/my-profile';
  /// Resolve staffCode from userCode + org + school.
  static const String staffCodeByUser = '/api/v1/staff/code';
  static const String staffDocuments = '/api/v1/staff-documents';
  static const String staffDocumentAdd = '/api/v1/staff-documents';
  static const String staffDocumentUpdate = '/api/v1/staff-documents';
  static const String staffDates = '/api/v1/staff-dates';
  static const String staffAddress = '/api/v1/staff-address';
  static const String staffSchedules = '/api/v1/staff-schedules';

  // School Users
  static const String schoolUsers = '/api/v1/school-users';
  static const String schoolUsersStaff = '/api/v1/school-users/staff';
  static const String schoolUsersDeactivate = '/api/v1/school-users/deactivate';
  static const String schoolUsersActivate = '/api/v1/school-users/activate';

  // Student
  static const String studentList = '/api/v1/student';
  static const String studentClassroom = '/api/v1/student-classroom';
  static const String studentClassroomAssignStudent =
      '/api/v1/student-classroom/assign-student';
  static const String studentDocuments = '/api/v1/student-documents';
  static String studentProfile(String code) => '/api/v1/student/$code';
  static String studentProfileUpdate(String code) => '/api/v1/student/$code/profile';
  /// Regular schedules for students (school-wide endpoint).
  /// PATCH body shape:
  /// {
  ///   "schoolCode": "string",
  ///   "studentCode": "string",
  ///   "schedule": [
  ///     {
  ///       "dayOfWeek": "MONDAY",
  ///       "startTime": { "hour": 0, "minute": 0, "second": 0, "nano": 0 },
  ///       "halfDay":  { "hour": 0, "minute": 0, "second": 0, "nano": 0 },
  ///       "endTime":  { "hour": 0, "minute": 0, "second": 0, "nano": 0 }
  ///     }
  ///   ]
  /// }
  static const String studentRegularSchedules = '/api/v1/regular-schedules';
  static String studentAddress(String code) => '/api/v1/student/$code/address';
  static String studentSiblings(String code) => '/api/v1/student/$code/siblings';
  static const String studentTags = '/api/v1/student-tags';
  static String studentDeactivate(String code) => '/api/v1/student/$code/deactivate';
  static String studentReactivate(String code) => '/api/v1/student/$code/reactivate';
  static String studentImportantDates(String code) =>
      '/api/v1/student/$code/important-dates';
  static String studentHealth(String code) => '/api/v1/student/$code/health';
  static String studentImmunization(String code) =>
      '/api/v1/student/$code/immunization';
  static String studentImmunizationRecord(String studentCode, String recordCode) =>
      '/api/v1/student/$studentCode/immunization/$recordCode';
  static String studentPhysicalExams(String code) =>
      '/api/v1/student/$code/physical-exam';
  static String studentPhysicalExam(String studentCode, String examCode) =>
      '/api/v1/student/$studentCode/physical-exam/$examCode';

  // Physicians
  static const String physicians = '/api/v1/physicians';

  // Guardian / Parent users
  static const String guardianUser = '/api/v1/guardian-user';
  static const String guardian = '/api/v1/guardian';
  static const String guardianExisting = '/api/v1/guardian/existing';

  // Tags
  static const String tags = '/api/v1/tags';

  // Attendance
  static const String studentAttendanceDailyView = '/api/v1/student-attendance/view/daily';
  static const String studentAttendanceCustomView = '/api/v1/student-attendance/view/custom';
  static const String studentAttendanceAbsentView = '/api/v1/student-attendance/view/absent';
  static const String studentAttendanceAbsentToggleView =
      '/api/v1/student-attendance/view/absent/toggle';
  static const String studentAttendanceProfile = '/api/v1/student-attendance/profile';
  static const String studentAttendanceProfileAbsentToggle =
      '/api/v1/student-attendance/profile/absent/toggle';
  static const String studentAttendanceSignInStatus =
      '/api/v1/student-attendance/sign-in/status';
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
  static const String studentAbsenceRecordsMarkAbsent =
      '/api/v1/student-absence-records/mark-absent';
  static const String studentAttendanceRecords = '/api/v1/student-attendance-records';
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
  static const String staffAttendanceDailyView = '/api/v1/staff-attendance/view/daily';
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
  static const String staffAttendanceProfile = '/api/v1/staff-attendance/profile';
  static const String staffAttendanceProfileAbsentToggle =
      '/api/v1/staff-attendance/profile/absent/toggle';
  static const String staffAttendanceAbsentView = '/api/v1/staff-attendance/view/absent';
  static const String staffAttendanceAbsentFormList =
      '/api/v1/staff-attendance/absent/form/list';
  static const String staffAttendanceAbsentToggleView =
      '/api/v1/staff-attendance/view/absent/toggle';
  static const String staffAttendanceCustomView = '/api/v1/staff-attendance/view/custom';
  static const String staffAttendanceRecordsSignIn =
      '/api/v1/staff-attendance-records/sign-in';
  static const String staffAttendanceRecordsSignInSelf =
      '/api/v1/staff-attendance-records/sign-in/self';
  static const String staffAttendanceRecordsSignOut =
      '/api/v1/staff-attendance-records/sign-out';
  static const String staffAttendanceRecordsTransfer =
      '/api/v1/staff-attendance-records/transfer';

  // Classroom
  static const String classroomAll = '/api/v1/classroom/all';
  static String classroomByCode(String code) => '/api/v1/classroom/$code';
  static const String classroomActivitySettingsRoot = '/api/v1/classrooms';

  // Activities
  static const String activities = '/api/v1/activities';
  static const String activityTypesRoot = '/api/v1/activity-types';

  // Pickup
  static const String pickup = '/api/v1/pickup';

  /// Helper to build a full URL from a relative path.
  static String url(String path) => '${ApiConstants.baseUrl}$path';

  /// Helper to build a full URL from a relative path with a custom base URL.
  static String urlWithBase(String path, String baseUrl) => '$baseUrl$path';
}

