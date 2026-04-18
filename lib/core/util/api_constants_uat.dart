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
}

class ApiConstantsUat {
  ApiConstantsUat._();

  /// UAT — single host.
  static const String _host = 'https://uat-wowcare.childcarewow.app';

  static const String baseUrl = _host;
  static const String staffBaseUrl = _host;
  static const String studentBaseUrl = _host;
  static const String classroomBaseUrl = _host;
  static const String schoolMs = _host;

  /// Attendance service base URL (UAT).
  ///
  /// Attendance APIs are served under: `$_host/api/v1/attendance/...`
  static const String attendanceBaseUrl = '$_host/api/v1/attendance';

  /// If activity/document are served on the same host in UAT, keep them as `_host`.
  static const String activityBaseUrl = _host;
  static const String documentMsBaseUrl = _host;

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
      default:
        return baseUrl;
    }
  }
}

