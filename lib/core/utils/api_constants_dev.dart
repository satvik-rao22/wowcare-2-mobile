/// DEV API constants — shared DEV gateway.
///
/// Same single-gateway shape as [ApiConstantsUat]/[ApiConstantsProd] — the
/// microservice segment lives in the PATH, not the host. Replaces the old
/// per-microservice-port DEV host (`5.78.83.44:{port}`); see git history on
/// `api_constants.dart` for that layout.
///
/// DEV is also the default build (no `--dart-define=ENVIRONMENT=...` needed):
///   flutter run
abstract final class ApiMicroservicesDev {
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

class ApiConstantsDev {
  ApiConstantsDev._();

  // ─── DEV gateway host ──────────────────────────────────────────────────────
  // Single gateway for all microservices in DEV (path holds the microservice
  // segment: `<_host>/api/v1/<ms>/...`), same shape as [ApiConstantsUat]/
  // [ApiConstantsProd]. Defaults to the real DEV gateway, but can be
  // overridden at run time without editing source, e.g.:
  //   flutter run --dart-define=API_HOST=https://jl69j4pz-8090.inc1.devtunnels.ms
  static const String _host = String.fromEnvironment(
    'API_HOST',
    // Matches WowInventory's DEV gateway (per the shared DEV Guide) — both
    // apps hit the same DEV backend, not two separate hosts.
    defaultValue: 'https://api-dev.childcarewow.app',
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
  /// DEV uses the Forte sandbox SDK, same as UAT.
  static const String forteEnv = 'sandbox';

  // ─── Microservice router ───────────────────────────────────────────────────

  static String baseUrlForMicroservice(String microserviceKey) {
    switch (microserviceKey) {
      case 'billing':
        return billingBaseUrl;
      case ApiMicroservicesDev.user:
        return baseUrl;
      case ApiMicroservicesDev.organization:
      case ApiMicroservicesDev.school:
        return schoolMs;
      case ApiMicroservicesDev.staff:
        return staffBaseUrl;
      case ApiMicroservicesDev.student:
        return studentBaseUrl;
      case ApiMicroservicesDev.classroom:
        return classroomBaseUrl;
      case ApiMicroservicesDev.attendance:
        return attendanceBaseUrl;
      case ApiMicroservicesDev.activity:
        return activityBaseUrl;
      case ApiMicroservicesDev.document:
        return documentMsBaseUrl;
      case ApiMicroservicesDev.communication:
        return communicationBaseUrl;
      case ApiMicroservicesDev.newsLatter:
        return newsLatterBaseUrl;
      case ApiMicroservicesDev.notification:
        return notificationBaseUrl;
      case ApiMicroservicesDev.scheduler:
        return schedulerBaseUrl;
      case ApiMicroservicesDev.eventsTodo:
        return eventsTodoBaseUrl;
      default:
        return baseUrl;
    }
  }
}
