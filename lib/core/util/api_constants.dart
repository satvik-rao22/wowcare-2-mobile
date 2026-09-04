import 'api_constants_prod.dart';
import 'api_constants_uat.dart';
import 'api_paths.dart';

/// Logical microservice key — used by [ApiConstants.baseUrlForMicroservice]
/// and [ApiPaths.microserviceKeyFromPath].
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
  static const String communication = 'communication';
  static const String newsLatter = 'newslatter';
  static const String notification = 'notification';
  static const String billing = 'billing';

  /// Events, Tasks & School Calendar (holidays) microservice.
  static const String scheduler = 'scheduler';

  /// Dedicated dev-environment service backing Events, Tasks & School
  /// Calendar (holidays). Independent of [scheduler].
  static const String eventsTodo = 'events-todo';
}

class ApiConstants {
  ApiConstants._();

  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'DEV',
  );

  static bool get isUat => _environment.toUpperCase() == 'UAT';

  static bool get isProd => _environment.toUpperCase() == 'PROD';

  /// DEV shared backend. Same *shape* as LOCAL — one host per microservice
  /// rather than a single gateway — so [isGatewayEnv] stays false and all of
  /// [ApiPaths]' direct-microservice path rules apply unchanged.
  static bool get isDev => _environment.toUpperCase() == 'DEV';

  /// DEV backend root. Plain HTTP, so cleartext must be permitted:
  /// `usesCleartextTraffic` in android/app/src/debug/AndroidManifest.xml and
  /// `NSAppTransportSecurity` in ios/Runner/Info.plist.
  static const String _devHost = 'http://5.78.83.44';

  /// `http://5.78.83.44:{port}[/{path}]`
  static String _devUrl(int port, [String? path]) =>
      path == null ? '$_devHost:$port' : '$_devHost:$port/$path';

  /// True for any single-gateway build (UAT or PROD), where the microservice
  /// segment lives in the URL path rather than the host — as opposed to
  /// LOCAL, where each microservice has its own devtunnel/ngrok host. UAT's
  /// path-routing rules ([ApiPathsUat]) apply unchanged to PROD, since both
  /// point at the same gateway contract, just a different host.
  static bool get isGatewayEnv => isUat || isProd;

  /// Forte tokenization environment passed into the auto-pay webview.
  ///
  /// The Forte JS SDK is loaded from `sandbox.forte.net` for any value other
  /// than `'prod'`, and from `api.forte.net` for `'prod'`. LOCAL and UAT use
  /// the sandbox gateway; PROD uses the live Forte gateway (real payment
  /// processing).
  static String get forteEnv => isProd
      ? ApiConstantsProd.forteEnv
      : isUat
      ? ApiConstantsUat.forteEnv
      : 'sandbox';

  static const _LocalDev _activeDev = _LocalDev.sairam;

  /// Resolved profile for the active developer.
  static _DevTunnel get _dev => _devTunnels[_activeDev]!;

  /// Per-developer devtunnel profiles.
  static const Map<_LocalDev, _DevTunnel> _devTunnels = {
    _LocalDev.sairam: _DevTunnel(
      id: 'wnmrl4rn',
      userPort: 8086,
      studentPort: 8085,
      classroomPort: 8087,
      staffPort: 8088,
      schoolPort: 8081,
      attendancePort: 8083,
      activityPort: 8082,
      communicationPort: 8087,
      // gatewayPort null → notification/billing/newsletter/document stay on ngrok.
    ),
    _LocalDev.preshita: _DevTunnel(
      id: 'qs176zl8',
      userPort: 8086,
      studentPort: 8085,
      classroomPort: 8082,
      staffPort: 8083,
      schoolPort: 8081,
      attendancePort: 8089,
      activityPort: 8084,
      communicationPort: 8082,
      // notification/billing/newsletter/document served from the devtunnel:8091.
      gatewayPort: 8091,
    ),
  };

  static const String _ngrokHost =
      'https://fitten-vallie-forthrightly.ngrok-free.dev';

  // ─── Service base URLs ─────────────────────────────────────────────────────

  /// User / Auth MS  (LOCAL: devtunnel | UAT/PROD: gateway)
  static String get baseUrl => isDev
      ? _devUrl(8082)
      : isProd
      ? ApiConstantsProd.baseUrl
      : isUat
      ? ApiConstantsUat.baseUrl
      : _dev.url(_dev.userPort);

  /// Student MS  (LOCAL: devtunnel | UAT/PROD: gateway)
  static String get studentBaseUrl => isDev
      ? _devUrl(8084)
      : isProd
      ? ApiConstantsProd.studentBaseUrl
      : isUat
      ? ApiConstantsUat.studentBaseUrl
      : _dev.url(_dev.studentPort);

  /// Classroom MS  (LOCAL: devtunnel | UAT/PROD: gateway)
  static String get classroomBaseUrl => isDev
      ? _devUrl(8088)
      : isProd
      ? ApiConstantsProd.classroomBaseUrl
      : isUat
      ? ApiConstantsUat.classroomBaseUrl
      : _dev.url(_dev.classroomPort);

  /// Staff MS  (LOCAL: devtunnel | UAT/PROD: gateway)
  static String get staffBaseUrl => isDev
      ? _devUrl(8083)
      : isProd
      ? ApiConstantsProd.staffBaseUrl
      : isUat
      ? ApiConstantsUat.staffBaseUrl
      : _dev.url(_dev.staffPort);

  /// School / Organization MS  (LOCAL: devtunnel | UAT/PROD: gateway)
  static String get schoolMs => isDev
      ? _devUrl(8081)
      : isProd
      ? ApiConstantsProd.schoolMs
      : isUat
      ? ApiConstantsUat.schoolMs
      : _dev.url(_dev.schoolPort);

  /// Attendance MS  (LOCAL: devtunnel/attendance | UAT/PROD: gateway)
  static String get attendanceBaseUrl => isDev
      ? _devUrl(8085, 'attendance-ms')
      : isProd
      ? ApiConstantsProd.attendanceBaseUrl
      : isUat
      ? ApiConstantsUat.attendanceBaseUrl
      : _dev.url(_dev.attendancePort, 'attendance');

  /// Activity MS  (LOCAL: devtunnel/wowcare-activity-ms | UAT/PROD: gateway)
  static String get activityBaseUrl => isDev
      ? _devUrl(8086)
      : isProd
      ? ApiConstantsProd.activityBaseUrl
      : isUat
      ? ApiConstantsUat.activityBaseUrl
      : _dev.url(_dev.activityPort, 'wowcare-activity-ms');

  /// Document MS  (LOCAL: gateway tunnel/ngrok | UAT/PROD: gateway)
  static String get documentMsBaseUrl => isDev
      ? _devUrl(8087, 'document-ms')
      : isProd
      ? ApiConstantsProd.documentMsBaseUrl
      : isUat
      ? ApiConstantsUat.documentMsBaseUrl
      : _dev.gatewayUrl('document-ms');

  /// Scheduler MS — Events, Tasks & School Calendar (holidays).
  /// DEV server exposes it as the `events-todo` service on port 8091
  /// (no context path — `http://5.78.83.44:8091`).
  static String get schedulerBaseUrl => isDev
      ? _devUrl(8091)
      : isUat
          ? ApiConstantsUat.schedulerBaseUrl
          : (_dev.schedulerPort != null
                ? _dev.url(_dev.schedulerPort!, 'scheduler')
                : _dev.gatewayUrl('scheduler'));

  /// Events/Todo MS — Events, Tasks & School Calendar (holidays).
  /// DEV server exposes it directly at `http://5.78.83.44:8091` (no context
  /// path). Kept independent from [schedulerBaseUrl].
  static String get eventsTodoBaseUrl => isDev
      ? _devUrl(8091)
      : isUat
          ? ApiConstantsUat.schedulerBaseUrl
          : (_dev.schedulerPort != null
                ? _dev.url(_dev.schedulerPort!, 'scheduler')
                : _dev.gatewayUrl('scheduler'));
  /// Communication / Messaging MS  (LOCAL: gateway tunnel/ngrok | UAT/PROD: gateway)
  static String get communicationBaseUrl => isDev
      ? _devUrl(8089)
      : isProd
      ? ApiConstantsProd.communicationBaseUrl
      : isUat
      ? ApiConstantsUat.communicationBaseUrl
      : _dev.gatewayUrl();

  /// Newsletter MS  (LOCAL: gateway tunnel/ngrok | UAT/PROD: gateway)
  static String get newsLatterBaseUrl => isDev
      ? _devUrl(8082)
      : isProd
      ? ApiConstantsProd.newsLatterBaseUrl
      : isUat
      ? ApiConstantsUat.newsLatterBaseUrl
      : _dev.gatewayUrl();

  /// Notification MS  (LOCAL: gateway tunnel/ngrok | UAT/PROD: gateway)
  static String get notificationBaseUrl => isDev
      ? _devUrl(8082)
      : isProd
      ? ApiConstantsProd.notificationBaseUrl
      : isUat
      ? ApiConstantsUat.notificationBaseUrl
      : _dev.gatewayUrl();

  /// Billing MS  (LOCAL: gateway tunnel/ngrok | UAT/PROD: gateway)
  static String get billingBaseUrl => isDev
      ? _devUrl(8082)
      : isProd
      ? ApiConstantsProd.billingBaseUrl
      : isUat
      ? ApiConstantsUat.billingBaseUrl
      : _dev.gatewayUrl();

  // ─── Endpoint helpers ──────────────────────────────────────────────────────

  static String qrCodeValidateEndpoint(String schoolCode) =>
      ApiPaths.url(ApiPaths.qrCodeValidate(schoolCode));

  static String qrCodeActiveEndpoint(String schoolCode) =>
      ApiPaths.url(ApiPaths.qrCodeActive(schoolCode));

  static String get kioskVerifyPinEndpoint =>
      ApiPaths.url(ApiPaths.kioskVerifyPin);

  // ─── Microservice router ───────────────────────────────────────────────────

  static String baseUrlForMicroservice(String microserviceKey) {
    if (isProd) {
      return ApiConstantsProd.baseUrlForMicroservice(microserviceKey);
    }
    if (isUat) return ApiConstantsUat.baseUrlForMicroservice(microserviceKey);
    switch (microserviceKey) {
      case ApiMicroservices.user:
        return baseUrl;
      case ApiMicroservices.organization:
      case ApiMicroservices.school:
        return schoolMs;
      case ApiMicroservices.staff:
        return staffBaseUrl;
      case ApiMicroservices.student:
        return studentBaseUrl;
      case ApiMicroservices.classroom:
        return classroomBaseUrl;
      case ApiMicroservices.attendance:
        return attendanceBaseUrl;
      case ApiMicroservices.activity:
        return activityBaseUrl;
      case ApiMicroservices.document:
        return documentMsBaseUrl;
      case ApiMicroservices.communication:
        return communicationBaseUrl;
      case ApiMicroservices.scheduler:
        return schedulerBaseUrl;
      case ApiMicroservices.eventsTodo:
        return eventsTodoBaseUrl;
      case ApiMicroservices.newsLatter:
        return newsLatterBaseUrl;
      case ApiMicroservices.notification:
        return notificationBaseUrl;
      case ApiMicroservices.billing:
        return billingBaseUrl;
      default:
        return baseUrl;
    }
  }

  static String get baseUrl1 => isDev
      ? _devUrl(8089)
      : isUat
      ? ApiConstantsUat.classroomBaseUrl
      : _dev.url(8089);
}

enum _LocalDev { sairam, preshita }

class _DevTunnel {
  const _DevTunnel({
    required this.id,
    required this.userPort,
    required this.studentPort,
    required this.classroomPort,
    required this.staffPort,
    required this.schoolPort,
    required this.attendancePort,
    required this.activityPort,
    required this.communicationPort,
    this.gatewayPort,
    this.schedulerPort,
  });

  /// Tunnel prefix before `-PORT.inc1.devtunnels.ms`.
  final String id;
  final int userPort;
  final int studentPort;
  final int classroomPort;
  final int staffPort;
  final int schoolPort;
  final int attendancePort;
  final int activityPort;
  final int communicationPort;

  /// Port for the shared gateway services (notification/billing/newsletter/
  /// document). When null, those services fall back to ngrok.
  final int? gatewayPort;

  /// Scheduler MS port on the devtunnel. When null, the scheduler falls back
  /// to the shared gateway host.
  final int? schedulerPort;

  /// `https://{id}-{port}.inc1.devtunnels.ms[/{path}]`
  String url(int port, [String? path]) {
    final base = 'https://$id-$port.inc1.devtunnels.ms';
    return path == null ? base : '$base/$path';
  }

  /// Base URL for the shared gateway services: the devtunnel on [gatewayPort]
  /// when set, otherwise ngrok.
  String gatewayUrl([String? path]) {
    final base = gatewayPort != null
        ? 'https://$id-$gatewayPort.inc1.devtunnels.ms'
        : ApiConstants._ngrokHost;
    return path == null ? base : '$base/$path';
  }
}
