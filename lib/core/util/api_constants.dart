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
}

class ApiConstants {
  ApiConstants._();

  // ─── Environment selector ──────────────────────────────────────────────────
  // Set at build time: `--dart-define=ENVIRONMENT=UAT`
  // Defaults to LOCAL when not supplied.
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'LOCAL',
  );

  static bool get isUat => _environment.toUpperCase() == 'UAT';

  // ─── LOCAL devtunnel config ────────────────────────────────────────────────
  // Each developer sets their own tunnel prefix here and nowhere else.
  // All LOCAL URLs are derived from this single constant.
  //
  // Known tunnel IDs:
  //   officeTunnelId  = '4hn0k1dg'   ← currently active
  //   sairamTunnelId  = 'wnmrl4rn'
  //   preshtiaTunnelId = 'qs176zl8'
  // To switch tunnel: replace the value of _localTunnelId below.
  // office='4hn0k1dg'  sairam='wnmrl4rn'  preshtia='qs176zl8'
  static const String _localTunnelId = '4hn0k1dg';

  static String _local(int port, [String? path]) {
    final base = 'https://$_localTunnelId-$port.inc1.devtunnels.ms';
    return path != null ? '$base/$path' : base;
  }

  // ─── Service base URLs ─────────────────────────────────────────────────────

  /// User / Auth MS  (LOCAL: 8090 | UAT: gateway)
  static String get baseUrl => isUat ? ApiConstantsUat.baseUrl : _local(8090);

  /// Student MS  (LOCAL: 8085 | UAT: gateway)
  static String get studentBaseUrl =>
      isUat ? ApiConstantsUat.studentBaseUrl : _local(8085);

  /// Classroom MS  (LOCAL: 8082 | UAT: gateway)
  static String get classroomBaseUrl =>
      isUat ? ApiConstantsUat.classroomBaseUrl : _local(8082);

  /// Staff MS  (LOCAL: 8083 | UAT: gateway)
  static String get staffBaseUrl =>
      isUat ? ApiConstantsUat.staffBaseUrl : _local(8083);

  /// School / Organization MS  (LOCAL: 8081 | UAT: gateway)
  static String get schoolMs => isUat ? ApiConstantsUat.schoolMs : _local(8081);

  /// Attendance MS  (LOCAL: 8083/attendance | UAT: gateway)
  static String get attendanceBaseUrl =>
      isUat ? ApiConstantsUat.attendanceBaseUrl : _local(8083, 'attendance');

  /// Activity MS  (LOCAL: 8084/wowcare-activity-ms | UAT: gateway)
  static String get activityBaseUrl => isUat
      ? ApiConstantsUat.activityBaseUrl
      : _local(8084, 'wowcare-activity-ms');

  /// Document MS  (LOCAL: ngrok | UAT: gateway)
  static String get documentMsBaseUrl => isUat
      ? ApiConstantsUat.documentMsBaseUrl
      : 'https://fitten-vallie-forthrightly.ngrok-free.dev/document-ms';

  /// Communication / Messaging MS  (LOCAL: 8086 | UAT: 8086)
  static String get communicationBaseUrl =>
      isUat ? ApiConstantsUat.communicationBaseUrl : _local(8087);

  /// Newsletter MS — shares the communication host.
  static String get newsLatterBaseUrl =>
      isUat ? ApiConstantsUat.newsLatterBaseUrl : communicationBaseUrl;

  /// Notification MS  (LOCAL: ngrok | UAT: gateway)
  static String get notificationBaseUrl => isUat
      ? ApiConstantsUat.notificationBaseUrl
      : 'https://fitten-vallie-forthrightly.ngrok-free.dev';

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
      default:
        return baseUrl;
    }
  }

  // ─── Legacy / unused ──────────────────────────────────────────────────────
  // Kept to avoid breaking any call sites that still reference these.
  static String get baseUrl1 =>
      isUat ? ApiConstantsUat.classroomBaseUrl : _local(8089);
}
