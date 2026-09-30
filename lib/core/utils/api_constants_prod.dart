/// PROD API constants — real production server only.
///
/// No devtunnel URLs belong here. Devtunnels live in [ApiConstants] under
/// the LOCAL branch (controlled by `_localTunnelId`).
///
/// To switch to PROD build:
///   flutter run --dart-define=ENVIRONMENT=PROD
abstract final class ApiMicroservicesProd {
  static const String user = 'user';
  static const String organization = 'organization';
  static const String school = 'school';
  static const String staff = 'staff';
  static const String student = 'student';
  static const String classroom = 'classroom';
  static const String attendance = 'attendance';
  static const String activity = 'activity';
  static const String document = 'document';
  static const String communication = 'communication';
  static const String notification = 'notification';
  static const String newsLatter = 'newslatter';
  static const String scheduler = 'scheduler';
  static const String eventsTodo = 'events-todo';
}

class ApiConstantsProd {
  ApiConstantsProd._();

  // ─── PROD gateway host ─────────────────────────────────────────────────────
  // Single gateway for all microservices in PROD (path holds the microservice
  // segment: `<_host>/api/v1/<ms>/...`), same shape as [ApiConstantsUat].
  // Defaults to the real production gateway, but can be overridden at run
  // time to point the same gateway-mode build at a different backend without
  // editing source, e.g.:
  //   flutter run --dart-define=ENVIRONMENT=PROD \
  //     --dart-define=API_HOST=https://jl69j4pz-8090.inc1.devtunnels.ms
  static const String _host = String.fromEnvironment(
    'API_HOST',
    defaultValue: 'https://api.childcarewow.app',
  );

  // ─── Per-service base URLs ─────────────────────────────────────────────────
  // Single gateway: the microservice segment lives in the PATH
  // (`<_host>/api/v1/<ms>/...`), not the host — so every base URL is just [_host].
  static const String baseUrl = _host;
  static const String staffBaseUrl = _host;
  static const String studentBaseUrl = _host;
  static const String classroomBaseUrl = _host;
  static const String schoolMs = _host;
  static const String activityBaseUrl = _host;
  static const String notificationBaseUrl = _host;
  static const String attendanceBaseUrl = _host;
  static const String documentMsBaseUrl = _host;
  static const String communicationBaseUrl = _host;
  static const String billingBaseUrl = _host;
  static const String newsLatterBaseUrl = _host;
  static const String schedulerBaseUrl = _host;
  static const String eventsTodoBaseUrl = _host;

  // ─── Forte (auto-pay tokenization) ─────────────────────────────────────────
  /// Forte environment used by the auto-pay webview in PROD. The Forte JS SDK
  /// loads from `api.forte.net` (live payment processing) instead of
  /// `sandbox.forte.net`.
  static const String forteEnv = 'prod';

  // ─── Microservice router ───────────────────────────────────────────────────

  static String baseUrlForMicroservice(String microserviceKey) {
    switch (microserviceKey) {
      case 'billing':
        return billingBaseUrl;
      case ApiMicroservicesProd.user:
        return baseUrl;
      case ApiMicroservicesProd.organization:
      case ApiMicroservicesProd.school:
        return schoolMs;
      case ApiMicroservicesProd.staff:
        return staffBaseUrl;
      case ApiMicroservicesProd.student:
        return studentBaseUrl;
      case ApiMicroservicesProd.classroom:
        return classroomBaseUrl;
      case ApiMicroservicesProd.attendance:
        return attendanceBaseUrl;
      case ApiMicroservicesProd.activity:
        return activityBaseUrl;
      case ApiMicroservicesProd.document:
        return documentMsBaseUrl;
      case ApiMicroservicesProd.communication:
        return communicationBaseUrl;
      case ApiMicroservicesProd.newsLatter:
        return newsLatterBaseUrl;
      case ApiMicroservicesProd.notification:
        return notificationBaseUrl;
      case ApiMicroservicesProd.scheduler:
        return schedulerBaseUrl;
      case ApiMicroservicesProd.eventsTodo:
        return eventsTodoBaseUrl;
      default:
        return baseUrl;
    }
  }
}
