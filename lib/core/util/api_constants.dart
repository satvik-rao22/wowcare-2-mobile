import 'api_constants_uat.dart';

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

// Previous single devtunnel (9000) + split attendance/activity hosts.
// class ApiConstants {
//   ApiConstants._();
//
//   /// Single backend base URL - all APIs run on port 9000.
//   static const String _host = 'https://qs176zl8-9000.inc1.devtunnels.ms';
//   static const String baseUrl = _host;
//
//   /// All services use the same base on port 9000.
//   static const String staffBaseUrl = _host;
//   static const String studentBaseUrl = _host;
//   static const String classroomBaseUrl = _host;
//   static const String schoolMs = _host;
//
//   /// Attendance service base URL
//   static const String attendanceBaseUrl =
//       'https://wnmrl4rn-8083.inc1.devtunnels.ms/attendance';
//
//   /// Activity service base URL
//   static const String activityBaseUrl =
//       'https://wnmrl4rn-8082.inc1.devtunnels.ms/wowcare-activity-ms';
//   // static const String baseUrlDev = 'https://242sq05v-8080.inc1.devtunnels.ms';
//   // static const String Prathmesh = 'https://qs176zl8-8080.inc1.devtunnels.ms';
//   // static const String Sairam = 'https://qs176zl8-8086.inc1.devtunnels.ms/wowcare-school-ms';
//   // static const String schoolMsNgrok = 'https://fitten-vallie-forthrightly.ngrok-free.dev';
// }


/// Logical id for [ApiConstants.baseUrlForMicroservice] (not a path segment).
/// Host is chosen from the first resource segment after `/api/v1/` via [ApiPaths.microserviceKeyFromPath].
abstract final class ApiMicroservices {
  static const String user = 'user';
  static const String organization = 'organization';
  static const String school = 'school';
  static const String staff = 'staff';
  static const String student = 'student';
  static const String classroom = 'classroom';
  static const String attendance = 'attendance';
  static const String activity = 'activity';
  static const String document = 'document';
}

// UAT (single host for all REST) — swap back in when pointing at production/UAT.
// class ApiConstants {
//   ApiConstants._();
//
//   /// UAT — https://uat-wowcare.childcarewow.app
//   static const String _host = 'https://uat-wowcare.childcarewow.app';
//   static const String baseUrl = _host;
//
//   static const String staffBaseUrl = _host;
//   static const String studentBaseUrl = _host;
//   static const String classroomBaseUrl = _host;
//   static const String schoolMs = _host;
//
//   /// Attendance service base URL
//   static const String attendanceBaseUrl =
//       'https://wnmrl4rn-8083.inc1.devtunnels.ms/attendance';
//
//   /// Activity service base URL
//   static const String activityBaseUrl =
//       'https://wnmrl4rn-8082.inc1.devtunnels.ms/wowcare-activity-ms';
//
//   /// Resolves host for [microserviceKey] (see [ApiMicroservices]).
//   static String baseUrlForMicroservice(String microserviceKey) {
//     switch (microserviceKey) {
//       case ApiMicroservices.staff:
//         return staffBaseUrl;
//       case ApiMicroservices.student:
//         return studentBaseUrl;
//       case ApiMicroservices.classroom:
//         return classroomBaseUrl;
//       case ApiMicroservices.organization:
//       case ApiMicroservices.school:
//         return schoolMs;
//       case ApiMicroservices.attendance:
//         return attendanceBaseUrl;
//       case ApiMicroservices.activity:
//         return activityBaseUrl;
//       case ApiMicroservices.user:
//       default:
//         return baseUrl;
//     }
//   }
// }

// Previous devtunnel block (kept for quick switch-back).
// class ApiConstants {
//   ApiConstants._();
//   static const String baseUrl = 'https://qs176zl8-8086.inc1.devtunnels.ms';
//   static const String studentBaseUrl = 'https://qs176zl8-8085.inc1.devtunnels.ms';
//   static const String classroomBaseUrl = 'https://qs176zl8-8082.inc1.devtunnels.ms';
//   static const String staffBaseUrl = 'https://qs176zl8-8083.inc1.devtunnels.ms';
//   static const String schoolMs = 'https://qs176zl8-8081.inc1.devtunnels.ms';
//   static const String attendanceBaseUrl = 'https://qs176zl8-8083.inc1.devtunnels.ms/attendance';
//   static const String activityBaseUrl = 'https://qs176zl8-8084.inc1.devtunnels.ms/wowcare-activity-ms';
// }

/// Devtunnel — per microservice (Swagger on each host, prefix `qs176zl8`).
/// | Service    | Swagger / base |
/// | User       | https://qs176zl8-8086.inc1.devtunnels.ms |
/// | Student    | https://qs176zl8-8085.inc1.devtunnels.ms |
/// | Classroom  | https://qs176zl8-8082.inc1.devtunnels.ms |
/// | Staff      | https://qs176zl8-8083.inc1.devtunnels.ms |
/// | School     | https://qs176zl8-8081.inc1.devtunnels.ms |
/// | Activity   | https://qs176zl8-8084.inc1.devtunnels.ms/wowcare-activity-ms |
/// | Document   | https://qs176zl8-8000.inc1.devtunnels.ms (presign under `/document-ms/...`) |
class ApiConstants {
  ApiConstants._();

  /// Build-time environment selector.
  /// Set with: `--dart-define=ENVIRONMENT=UAT` (otherwise defaults to LOCAL).
  static const String _environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'LOCAL');

  static bool get isUat => _environment.toUpperCase() == 'UAT';

  /// Tunnel sets (prefix before `-PORT.inc1.devtunnels.ms`)
  static const String preshtiaTunnelId = 'qs176zl8';
  static const String sairamTunnelId = 'wnmrl4rn';

  /// Active LOCAL tunnel set.
  static const String _localTunnelId = sairamTunnelId;

  /// User MS (LOCAL devtunnel) or UAT base host.
  static String get baseUrl => isUat
      ? ApiConstantsUat.baseUrl
      : 'https://$_localTunnelId-8086.inc1.devtunnels.ms';

  /// Student MS (LOCAL devtunnel) or UAT base host.
  static String get studentBaseUrl => isUat
      ? ApiConstantsUat.studentBaseUrl
      : 'https://$_localTunnelId-8085.inc1.devtunnels.ms';

  /// Classroom MS (LOCAL devtunnel) or UAT base host.
  static String get classroomBaseUrl => isUat
      ? ApiConstantsUat.classroomBaseUrl
      : 'https://$_localTunnelId-8087.inc1.devtunnels.ms';

  /// Staff MS (LOCAL devtunnel) or UAT base host.
  static String get staffBaseUrl => isUat
      ? ApiConstantsUat.staffBaseUrl
      : 'https://$_localTunnelId-8088.inc1.devtunnels.ms';

  /// School / organization MS (LOCAL devtunnel) or UAT base host.
  static String get schoolMs => isUat
      ? ApiConstantsUat.schoolMs
      : 'https://$_localTunnelId-8081.inc1.devtunnels.ms';

  /// Attendance base (LOCAL devtunnel) or UAT base host.
  static String get attendanceBaseUrl => isUat
      ? ApiConstantsUat.attendanceBaseUrl
      : '$staffBaseUrl/attendance';

  /// Activity base (LOCAL devtunnel) or UAT base host.
  static String get activityBaseUrl => isUat
      ? ApiConstantsUat.activityBaseUrl
      : 'https://$_localTunnelId-8082.inc1.devtunnels.ms/wowcare-activity-ms';

  /// Document MS base (LOCAL devtunnel) or UAT base host.
  ///
  /// Root UAT constants may not define a dedicated document host; in that case we
  /// default to the main base URL.
  static String get documentMsBaseUrl =>
      isUat
          ? ApiConstantsUat.documentMsBaseUrl
          : 'https://fitten-vallie-forthrightly.ngrok-free.dev/document-ms';

  /// Resolves host for [microserviceKey] (see [ApiMicroservices]).
  static String baseUrlForMicroservice(String microserviceKey) {
    if (isUat) return ApiConstantsUat.baseUrlForMicroservice(microserviceKey);
    switch (microserviceKey) {
      case ApiMicroservices.staff:
        return staffBaseUrl;
      case ApiMicroservices.student:
        return studentBaseUrl;
      case ApiMicroservices.classroom:
        return classroomBaseUrl;
      case ApiMicroservices.organization:
      case ApiMicroservices.school:
        return schoolMs;
      case ApiMicroservices.attendance:
        return attendanceBaseUrl;
      case ApiMicroservices.activity:
        return activityBaseUrl;
      case ApiMicroservices.document:
        return documentMsBaseUrl;
      case ApiMicroservices.user:
      default:
        return baseUrl;
    }
  }
  // static const String baseUrlDev = 'https://242sq05v-8080.inc1.devtunnels.ms';
  // static const String Prathmesh = 'https://qs176zl8-8080.inc1.devtunnels.ms';
  // static const String Sairam = 'https://qs176zl8-8086.inc1.devtunnels.ms/wowcare-school-ms';
  // static const String schoolMsNgrok = 'https://fitten-vallie-forthrightly.ngrok-free.dev';
}
