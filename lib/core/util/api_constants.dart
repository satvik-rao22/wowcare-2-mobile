class ApiConstants {
  ApiConstants._();

  /// Backend services run on different ports (devtunnel).
  /// user-->8080, school-->8081, classroom-->8082, staff-->8083, student-->8085
  static const String baseUrl = 'https://qs176zl8-8080.inc1.devtunnels.ms';
  static const String schoolMs = 'https://qs176zl8-8081.inc1.devtunnels.ms';
  static const String classroomBaseUrl = 'https://qs176zl8-8082.inc1.devtunnels.ms';
  static const String staffBaseUrl = 'https://qs176zl8-8083.inc1.devtunnels.ms';
  static const String studentBaseUrl = 'https://qs176zl8-8085.inc1.devtunnels.ms';

  /// Attendance service base URL
  static const String attendanceBaseUrl =
      'https://qs176zl8-8083.inc1.devtunnels.ms/attendance';

  /// Activity service base URL
  static const String activityBaseUrl =
      'https://qs176zl8-8084.inc1.devtunnels.ms/wowcare-activity-ms';
  // static const String baseUrlDev = 'https://242sq05v-8080.inc1.devtunnels.ms';
  // static const String Prathmesh = 'https://qs176zl8-8080.inc1.devtunnels.ms';
  // static const String Sairam = 'https://qs176zl8-8086.inc1.devtunnels.ms/wowcare-school-ms';
  // static const String schoolMsNgrok = 'https://fitten-vallie-forthrightly.ngrok-free.dev';
}

