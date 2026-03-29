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

/// Devtunnel — per microservice (Swagger on each host, prefix `wnmrl4rn`).
/// | Service    | Swagger / base |
/// | User       | https://wnmrl4rn-8086.inc1.devtunnels.ms |
/// | Student    | https://wnmrl4rn-8085.inc1.devtunnels.ms |
/// | Classroom  | https://wnmrl4rn-8087.inc1.devtunnels.ms |
/// | Staff      | https://wnmrl4rn-8088.inc1.devtunnels.ms |
/// | School     | https://wnmrl4rn-8081.inc1.devtunnels.ms |
/// | Activity   | https://wnmrl4rn-8082.inc1.devtunnels.ms/wowcare-activity-ms |
/// | Document   | https://wnmrl4rn-8000.inc1.devtunnels.ms (presign under `/document-ms/...`) |
class ApiConstants {
  ApiConstants._();

  /// User MS (8086)
  static const String baseUrl = 'https://wnmrl4rn-8086.inc1.devtunnels.ms';

  /// Student MS (8085)
  static const String studentBaseUrl =
      'https://wnmrl4rn-8085.inc1.devtunnels.ms';

  /// Classroom MS (8087)
  static const String classroomBaseUrl =
      'https://wnmrl4rn-8087.inc1.devtunnels.ms';

  /// Staff MS (8088)
  static const String staffBaseUrl = 'https://wnmrl4rn-8088.inc1.devtunnels.ms';

  /// School / organization MS (8081)
  static const String schoolMs = 'https://wnmrl4rn-8081.inc1.devtunnels.ms';

  /// Attendance — API base with path prefix (adjust if attendance runs on another tunnel).
  static const String attendanceBaseUrl =
      'https://wnmrl4rn-8083.inc1.devtunnels.ms/attendance';

  /// Activity MS (8082, context path `/wowcare-activity-ms`)
  static const String activityBaseUrl =
      'https://wnmrl4rn-8082.inc1.devtunnels.ms/wowcare-activity-ms';

  /// Document MS — host only. Upload-session responses return a path like
  /// `/document-ms/api/v1`; presign is **not** routed on the activity host in devtunnel.
  /// Use the gateway tunnel that serves document-ms (e.g. **8000**), not 8082.
  static const String documentMsBaseUrl =
      'https://wnmrl4rn-8000.inc1.devtunnels.ms';

  /// Resolves host for [microserviceKey] (see [ApiMicroservices]).
  static String baseUrlForMicroservice(String microserviceKey) {
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
