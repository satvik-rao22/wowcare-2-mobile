

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

/// Devtunnel — per microservice (Swagger on each host, prefix `qs176zl8`).
/// | Service    | Swagger / base |
/// | Staff      | https://qs176zl8-8083.inc1.devtunnels.ms/swagger-ui/index.html#/ |
/// | User       | https://qs176zl8-8086.inc1.devtunnels.ms/swagger-ui/index.html#/ |
/// | School     | https://qs176zl8-8081.inc1.devtunnels.ms/swagger-ui/index.html#/ |
/// | Classroom  | https://qs176zl8-8082.inc1.devtunnels.ms/swagger-ui/index.html#/ |
/// | Student    | https://qs176zl8-8085.inc1.devtunnels.ms/swagger-ui/index.html#/ |
/// | Activity   | https://qs176zl8-8084.inc1.devtunnels.ms/wowcare-activity-ms/swagger-ui/swagger-ui/index.html#/ |
class ApiConstants {
  ApiConstants._();

  /// User MS (8086)
  static const String baseUrl = 'https://qs176zl8-8086.inc1.devtunnels.ms';

  /// Student MS (8085)
  static const String studentBaseUrl =
      'https://qs176zl8-8085.inc1.devtunnels.ms';

  /// Classroom MS (8082)
  static const String classroomBaseUrl =
      'https://qs176zl8-8082.inc1.devtunnels.ms';

  /// Staff MS (8083)
  static const String staffBaseUrl = 'https://qs176zl8-8083.inc1.devtunnels.ms';

  /// School / organization MS (8081)
  static const String schoolMs = 'https://qs176zl8-8081.inc1.devtunnels.ms';

  /// Attendance — API base with path prefix (adjust if attendance runs on another tunnel).
  static const String attendanceBaseUrl =
      'https://qs176zl8-8083.inc1.devtunnels.ms/attendance';

  /// Activity MS (8084, context path `/wowcare-activity-ms`)
  static const String activityBaseUrl =
      'https://qs176zl8-8084.inc1.devtunnels.ms/wowcare-activity-ms';

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
