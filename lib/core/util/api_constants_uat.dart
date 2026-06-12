/// UAT API constants — real UAT server only.
///
/// No devtunnel URLs belong here. Devtunnels live in [ApiConstants] under
/// the LOCAL branch (controlled by `_localTunnelId`).
///
/// To switch to UAT build:
///   flutter run --dart-define=ENVIRONMENT=UAT
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
  static const String newsLatter = 'newslatter';
}

class ApiConstantsUat {
  ApiConstantsUat._();

  // ─── UAT gateway host ──────────────────────────────────────────────────────
  // Single gateway for all microservices in UAT.
  // Update this when the UAT hostname changes.
  static const String _host = 'https://uat-wowcare.childcarewow.app';
  // static const String _host = 'https://4hn0k1dg-8090.inc1.devtunnels.ms/';

  // ─── Per-service base URLs ─────────────────────────────────────────────────
  static const String baseUrl = _host;
  static const String staffBaseUrl = _host;
  static const String studentBaseUrl = _host;
  static const String classroomBaseUrl = _host;
  static const String schoolMs = _host;
  static const String activityBaseUrl = _host;
  static const String newsLatterBaseUrl = _host;
  static const String notificationBaseUrl = _host;
  static const String attendanceBaseUrl = _host;
  static const String documentMsBaseUrl = _host;
  static const String communicationBaseUrl = _host;
  static const String billingBaseUrl = _host;

  // ─── Microservice router ───────────────────────────────────────────────────

  static String baseUrlForMicroservice(String microserviceKey) {
    switch (microserviceKey) {
      case 'billing':
        return billingBaseUrl;
      case ApiMicroservicesUat.user:
        return baseUrl;
      case ApiMicroservicesUat.organization:
      case ApiMicroservicesUat.school:
        return schoolMs;
      case ApiMicroservicesUat.staff:
        return staffBaseUrl;
      case ApiMicroservicesUat.student:
        return studentBaseUrl;
      case ApiMicroservicesUat.classroom:
        return classroomBaseUrl;
      case ApiMicroservicesUat.attendance:
        return attendanceBaseUrl;
      case ApiMicroservicesUat.activity:
        return activityBaseUrl;
      case ApiMicroservicesUat.document:
        return documentMsBaseUrl;
      case ApiMicroservicesUat.communication:
        return communicationBaseUrl;
      case ApiMicroservicesUat.newsLatter:
        return newsLatterBaseUrl;
      case ApiMicroservicesUat.notification:
        return notificationBaseUrl;
      default:
        return baseUrl;
    }
  }
}
