// Previous multi-port devtunnel layout (user/school/classroom/staff/student).
// class ApiConstants {
//   ApiConstants._();
//
//   /// Backend services run on different ports (devtunnel).
//   /// user-->8080, school-->8081, classroom-->8082, staff-->8083, student-->8085
//   static const String baseUrl = 'https://qs176zl8-8080.inc1.devtunnels.ms';
//   static const String schoolMs = 'https://qs176zl8-8081.inc1.devtunnels.ms';
//   static const String classroomBaseUrl = 'https://qs176zl8-8082.inc1.devtunnels.ms';
//   static const String staffBaseUrl = 'https://qs176zl8-8083.inc1.devtunnels.ms';
//   static const String studentBaseUrl = 'https://qs176zl8-8085.inc1.devtunnels.ms';
//
//   /// Attendance service base URL
//   static const String attendanceBaseUrl =
//       'https://qs176zl8-8083.inc1.devtunnels.ms/attendance';
//
//   /// Activity service base URL
//   static const String activityBaseUrl =
//       'https://qs176zl8-8084.inc1.devtunnels.ms/wowcare-activity-ms';
// }

class ApiConstants {
  ApiConstants._();

  /// Toggle this flag to switch local setups.
  /// false -> current setup (qs176zl8), true -> alternate setup (wnmrl4rn).
  static const bool useAlternateLocalSetup = true;

  // Current local setup (qs176zl8)
  static const String _currentUserUrl = 'https://qs176zl8-8086.inc1.devtunnels.ms';
  static const String _currentStudentUrl = 'https://qs176zl8-8085.inc1.devtunnels.ms';
  static const String _currentClassroomUrl = 'https://qs176zl8-8082.inc1.devtunnels.ms';
  static const String _currentStaffUrl = 'https://qs176zl8-8083.inc1.devtunnels.ms';
  static const String _currentSchoolUrl = 'https://qs176zl8-8081.inc1.devtunnels.ms';
  static const String _currentAttendanceUrl = 'https://wnmrl4rn-8083.inc1.devtunnels.ms/attendance';
  static const String _currentActivityUrl =
      'https://qs176zl8-8084.inc1.devtunnels.ms/wowcare-activity-ms';

  // Alternate local setup (wnmrl4rn)
  static const String _alternateUserUrl = 'https://wnmrl4rn-8086.inc1.devtunnels.ms';
  static const String _alternateStudentUrl = 'https://wnmrl4rn-8085.inc1.devtunnels.ms';
  static const String _alternateClassroomUrl = 'https://wnmrl4rn-8087.inc1.devtunnels.ms';
  static const String _alternateStaffUrl = 'https://wnmrl4rn-8088.inc1.devtunnels.ms';
  static const String _alternateSchoolUrl = 'https://wnmrl4rn-8081.inc1.devtunnels.ms';
  static const String _alternateAttendanceUrl = 'https://wnmrl4rn-8083.inc1.devtunnels.ms/attendance';
  static const String _alternateActivityUrl =
      'https://wnmrl4rn-8082.inc1.devtunnels.ms/wowcare-activity-ms';

  /// Public URLs used by the app.
  static const String baseUrl =
      useAlternateLocalSetup ? _alternateUserUrl : _currentUserUrl;
  static const String studentBaseUrl =
      useAlternateLocalSetup ? _alternateStudentUrl : _currentStudentUrl;
  static const String classroomBaseUrl =
      useAlternateLocalSetup ? _alternateClassroomUrl : _currentClassroomUrl;
  static const String staffBaseUrl =
      useAlternateLocalSetup ? _alternateStaffUrl : _currentStaffUrl;
  static const String schoolMs =
      useAlternateLocalSetup ? _alternateSchoolUrl : _currentSchoolUrl;
  static const String attendanceBaseUrl =
      useAlternateLocalSetup ? _alternateAttendanceUrl : _currentAttendanceUrl;
  static const String activityBaseUrl =
      useAlternateLocalSetup ? _alternateActivityUrl : _currentActivityUrl;
  // static const String baseUrlDev = 'https://242sq05v-8080.inc1.devtunnels.ms';
  // static const String Prathmesh = 'https://qs176zl8-8080.inc1.devtunnels.ms';
  // static const String Sairam = 'https://qs176zl8-8086.inc1.devtunnels.ms/wowcare-school-ms';
  // static const String schoolMsNgrok = 'https://fitten-vallie-forthrightly.ngrok-free.dev';
}
