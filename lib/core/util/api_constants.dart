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
}

class ApiConstants {
  ApiConstants._();


  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'LOCAL',
  );

  static bool get isUat => _environment.toUpperCase() == 'UAT';

  /// Forte tokenization environment passed into the auto-pay webview.
  ///
  /// The Forte JS SDK is loaded from `sandbox.forte.net` for any value other
  /// than `'prod'`, and from `api.forte.net` for `'prod'`. We use the sandbox
  /// gateway for both LOCAL and UAT today; flip this to `'prod'` (or branch on
  /// a future PROD environment) when the production Forte gateway is wired.
  static String get forteEnv =>
      isUat ? ApiConstantsUat.forteEnv : 'sandbox';


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

  /// User / Auth MS  (LOCAL: devtunnel | UAT: gateway)
  static String get baseUrl =>
      isUat ? ApiConstantsUat.baseUrl : _dev.url(_dev.userPort);

  /// Student MS  (LOCAL: devtunnel | UAT: gateway)

  static String get studentBaseUrl =>
      isUat ? ApiConstantsUat.studentBaseUrl : _dev.url(_dev.studentPort);

  /// Classroom MS  (LOCAL: devtunnel | UAT: gateway)
  static String get classroomBaseUrl =>
      isUat ? ApiConstantsUat.classroomBaseUrl : _dev.url(_dev.classroomPort);

  /// Staff MS  (LOCAL: devtunnel | UAT: gateway)
  static String get staffBaseUrl =>
      isUat ? ApiConstantsUat.staffBaseUrl : _dev.url(_dev.staffPort);

  /// School / Organization MS  (LOCAL: devtunnel | UAT: gateway)
  static String get schoolMs =>
      isUat ? ApiConstantsUat.schoolMs : _dev.url(_dev.schoolPort);

  /// Attendance MS  (LOCAL: devtunnel/attendance | UAT: gateway)
  static String get attendanceBaseUrl => isUat
      ? ApiConstantsUat.attendanceBaseUrl
      : _dev.url(_dev.attendancePort, 'attendance');

  /// Activity MS  (LOCAL: devtunnel/wowcare-activity-ms | UAT: gateway)
  static String get activityBaseUrl => isUat
      ? ApiConstantsUat.activityBaseUrl
      : _dev.url(_dev.activityPort, 'wowcare-activity-ms');

  /// Document MS  (LOCAL: gateway tunnel/ngrok | UAT: gateway)
  static String get documentMsBaseUrl => isUat
      ? ApiConstantsUat.documentMsBaseUrl
      : _dev.gatewayUrl('document-ms');

  /// Communication / Messaging MS  (LOCAL: gateway:8091 when set, else devtunnel
  /// communicationPort | UAT: gateway)
  static String get communicationBaseUrl => isUat
      ? ApiConstantsUat.communicationBaseUrl
      : (_dev.gatewayPort != null
            ? _dev.url(_dev.gatewayPort!)
            : _dev.url(_dev.communicationPort));

  /// Newsletter MS  (LOCAL: gateway tunnel/ngrok | UAT: gateway)
  static String get newsLatterBaseUrl =>
      isUat ? ApiConstantsUat.newsLatterBaseUrl : _dev.gatewayUrl();

  /// Notification MS  (LOCAL: gateway tunnel/ngrok | UAT: gateway)
  static String get notificationBaseUrl =>
      isUat ? ApiConstantsUat.notificationBaseUrl : _dev.gatewayUrl();

  /// Billing MS  (LOCAL: gateway tunnel/ngrok | UAT: gateway)
  static String get billingBaseUrl =>
      isUat ? ApiConstantsUat.billingBaseUrl : _dev.gatewayUrl();

  // ─── Endpoint helpers ──────────────────────────────────────────────────────

  static String qrCodeValidateEndpoint(String schoolCode) =>
      ApiPaths.url(ApiPaths.qrCodeValidate(schoolCode));

  static String qrCodeActiveEndpoint(String schoolCode) =>
      ApiPaths.url(ApiPaths.qrCodeActive(schoolCode));

  static String get kioskVerifyPinEndpoint =>
      ApiPaths.url(ApiPaths.kioskVerifyPin);

  // ─── Microservice router ───────────────────────────────────────────────────

  static String baseUrlForMicroservice(String microserviceKey) {
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


  static String get baseUrl1 =>
      isUat ? ApiConstantsUat.classroomBaseUrl : _dev.url(8089);
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
