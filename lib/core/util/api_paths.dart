import 'api_constants.dart';

class ApiPaths {
  ApiPaths._();

  // Auth
  static const String authLogin = '/api/v1/auth/login';
  static const String authLogout = '/api/v1/auth/logout';
  static const String authForgotPassword = '/api/v1/auth/forgot-password';

  // School
  static const String schoolNamesByOrg = '/api/v1/schools/names-by-org';
  static const String organizationNames = '/api/v1/organizations/names';

  // Staff
  static const String staffList = '/api/v1/staff';
  static const String staffCount = '/api/v1/staff/count';
  static const String staffProfile = '/api/v1/staff';
  static const String staffDocuments = '/api/v1/staff-documents';
  static const String staffDocumentAdd = '/api/v1/staff-documents';
  static const String staffDocumentUpdate = '/api/v1/staff-documents/documents';
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

  // Classroom
  static const String classroomAll = '/api/v1/classroom/all';

  /// Helper to build a full URL from a relative path.
  static String url(String path) => '${ApiConstants.baseUrl}$path';

  /// Helper to build a full URL from a relative path with a custom base URL.
  static String urlWithBase(String path, String baseUrl) => '$baseUrl$path';
}

