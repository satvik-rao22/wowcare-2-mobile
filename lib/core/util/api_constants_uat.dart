/// UAT API constants.
///
/// This file is intentionally separate from the local/dev constants so builds can
/// switch between them using `--dart-define=ENVIRONMENT=UAT`.
abstract final class ApiMicroservicesUat {
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
}

class ApiConstantsUat {
  ApiConstantsUat._();

  // static const _host = 'https://4hn0k1dg-8090.inc1.devtunnels.ms';
  static const _host = 'https://uat-wowcare.childcarewow.app';

  static const String baseUrl = _host;
  static const String staffBaseUrl = _host;
  static const String studentBaseUrl = _host;
  static const String newsLatterBaseUrl = _host;
  static const String classroomBaseUrl = _host;
  static const String schoolMs = _host;

  /// Attendance service base URL (UAT).
  ///
  /// Attendance APIs are served under: `$_host/api/v1/attendance/...`
  static const String attendanceBaseUrl = '$_host/api/v1/attendance';

  /// Builds the full QR code validation URL for a given school (UAT).
  ///
  /// UAT gateway routes through the attendance microservice segment, so the
  /// path starts directly from `/schools/` after the attendance base:
  /// `$host/api/v1/attendance/schools/{code}/attendance-settings/qr-code/validate`
  static String qrCodeValidateEndpoint(String schoolCode) =>
      '$attendanceBaseUrl/schools/$schoolCode/attendance-settings/qr-code/validate';

  /// Activity APIs are on the shared UAT host.
  static const String activityBaseUrl = _host;

  /// Document APIs in UAT are rooted under `/api/v1/document`.
  static const String documentMsBaseUrl = '$_host/api/v1/document';
  static const String communicationBaseUrl = _host;

  /// Notification MS (FCM + delivery logs) — same host as Swagger gateway.
  static const String notificationBaseUrl =
      'https://fitten-vallie-forthrightly.ngrok-free.dev';

  static String baseUrlForMicroservice(String microserviceKey) {
    // In UAT we default to a single host; keep the switch for flexibility.
    switch (microserviceKey) {
      case ApiMicroservicesUat.staff:
        return staffBaseUrl;
      case ApiMicroservicesUat.student:
        return studentBaseUrl;
      case ApiMicroservicesUat.classroom:
        return classroomBaseUrl;
      case ApiMicroservicesUat.organization:
      case ApiMicroservicesUat.school:
        return schoolMs;
      case ApiMicroservicesUat.attendance:
        return attendanceBaseUrl;
      case ApiMicroservicesUat.activity:
        return activityBaseUrl;
      case ApiMicroservicesUat.document:
        return documentMsBaseUrl;
      case ApiMicroservicesUat.user:
      case ApiMicroservicesUat.communication:
        return communicationBaseUrl;
      case ApiMicroservicesUat.notification:
        return notificationBaseUrl;
      default:
        return baseUrl;
    }
  }
}
