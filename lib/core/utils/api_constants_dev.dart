/// DEV API constants — the shared DEV gateway.
///
/// DEV now runs the same single-gateway topology as UAT and PROD: one host for
/// every microservice, with the microservice segment in the path
/// (`<host>/api/v1/<ms>/...`). That is why [ApiConstants.isGatewayEnv] includes
/// DEV, and why the per-service base URLs below are all the same host.
///
///   flutter run --dart-define=ENVIRONMENT=DEV
///
/// Override the host without editing source — useful for pointing a DEV-mode
/// build at a devtunnel gateway:
///
///   flutter run --dart-define=ENVIRONMENT=DEV \
///     --dart-define=API_HOST=https://xxxx-8090.inc1.devtunnels.ms
class ApiConstantsDev {
  ApiConstantsDev._();

  static const String _host = String.fromEnvironment(
    'API_HOST',
    // Matches WowInventory's DEV gateway (per the shared DEV Guide) — both
    // apps hit the same DEV backend, not two separate hosts.
    defaultValue: 'https://api-dev.childcarewow.app',
  );

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

  /// Forte sandbox, as on UAT.
  static const String forteEnv = 'sandbox';
}
