class ApiConstants {
  ApiConstants._();

  /// Single backend base URL - all APIs run on port 9000.
  static const String _host = 'https://qs176zl8-9000.inc1.devtunnels.ms';
  static const String baseUrl = _host;

  /// All services use the same base on port 9000.
  static const String staffBaseUrl = _host;
  static const String studentBaseUrl = _host;
  static const String classroomBaseUrl = _host;
  static const String schoolMs = _host;

  /// Attendance service base URL
  static const String attendanceBaseUrl =
      'https://wnmrl4rn-8083.inc1.devtunnels.ms/attendance';

  /// Activity service base URL
  static const String activityBaseUrl =
      'https://wnmrl4rn-8082.inc1.devtunnels.ms/wowcare-activity-ms';
  // static const String baseUrlDev = 'https://242sq05v-8080.inc1.devtunnels.ms';
  // static const String Prathmesh = 'https://qs176zl8-8080.inc1.devtunnels.ms';
  // static const String Sairam = 'https://qs176zl8-8086.inc1.devtunnels.ms/wowcare-school-ms';
  // static const String schoolMsNgrok = 'https://fitten-vallie-forthrightly.ngrok-free.dev';
}

