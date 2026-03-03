import 'api_constants.dart';

class ApiPaths {
  ApiPaths._();

  // Auth
  static const String authLogin = '/api/v1/auth/login';
  static const String authLogout = '/api/v1/auth/logout';
  static const String authForgotPassword = '/api/v1/auth/forgot-password';
  static const String authLoginContext = '/api/v1/auth/login-context';

  // School - {organizationCode} in path
  static const String schoolNamesByOrg = '/api/v1/schools/names-by-org';
  static String schoolNamesByOrgPath(String orgCode) =>
      '$schoolNamesByOrg/$orgCode';
  static const String organizationNames = '/api/v1/organizations/names';

  // Staff
  static const String staffList = '/api/v1/staff';
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
  static const String studentDocuments = '/api/v1/student-documents';
  static String studentProfile(String code) => '/api/v1/student/$code';
  static String studentProfileUpdate(String code) => '/api/v1/student/$code/profile';
  static String studentDeactivate(String code) => '/api/v1/student/$code/deactivate';
  static String studentReactivate(String code) => '/api/v1/student/$code/reactivate';
  static String studentImportantDates(String code) =>
      '/api/v1/student/$code/important-dates';

  // Physicians
  static const String physicians = '/api/v1/physicians';

  // Guardian / Parent users
  static const String guardianUser = '/api/v1/guardian-user';
  static const String guardian = '/api/v1/guardian';

  // Attendance
  static const String studentAttendanceDailyView = '/api/v1/student-attendance/view/daily';
  static const String studentAttendanceCustomView = '/api/v1/student-attendance/view/custom';
  static const String studentAttendanceAbsentView = '/api/v1/student-attendance/view/absent';
  static const String studentAttendanceAbsentToggleView =
      '/api/v1/student-attendance/view/absent/toggle';
  static const String studentAttendanceProfile = '/api/v1/student-attendance/profile';
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
  static const String staffAttendanceDailyView = '/api/v1/staff-attendance/view/daily';
  static const String staffAttendanceSignInFormList =
      '/api/v1/staff-attendance/sign-in/form/list';
  static const String staffAttendanceProfile = '/api/v1/staff-attendance/profile';
  static const String staffAttendanceAbsentView = '/api/v1/staff-attendance/view/absent';
  static const String staffAttendanceCustomView = '/api/v1/staff-attendance/view/custom';

  // Classroom
  static const String classroomAll = '/api/v1/classroom/all';

  // Pickup
  static const String pickup = '/api/v1/pickup';

  /// Helper to build a full URL from a relative path.
  static String url(String path) => '${ApiConstants.baseUrl}$path';

  /// Helper to build a full URL from a relative path with a custom base URL.
  static String urlWithBase(String path, String baseUrl) => '$baseUrl$path';
}

