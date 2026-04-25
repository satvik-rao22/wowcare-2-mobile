import 'api_constants_uat.dart';
 
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
  static const String document = 'document';
  static const String communication = 'communication';
}
 
class ApiConstants {
  ApiConstants._();
 
  /// Build-time environment selector.
  /// Set with: `--dart-define=ENVIRONMENT=UAT` (otherwise defaults to LOCAL).
  static const String _environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'LOCAL',
  );
 
  static bool get isUat => _environment.toUpperCase() == 'UAT';
 
  static String get baseUrl1 => isUat
      ? ApiConstantsUat.classroomBaseUrl
      : 'https://qs176zl8-8089.inc1.devtunnels.ms';
 
  /// Tunnel sets (prefix before `-PORT.inc1.devtunnels.ms`)
  static const String preshtiaTunnelId = 'qs176zl8';
  static const String sairamTunnelId = 'wnmrl4rn';
 
  /// Active LOCAL tunnel set.
  static const String _localTunnelId = preshtiaTunnelId;
 
  /// User MS (LOCAL devtunnel) or UAT base host.
  static String get baseUrl => isUat
      ? ApiConstantsUat.baseUrl
      : 'https://$_localTunnelId-8086.inc1.devtunnels.ms';
 
  /// Student MS (LOCAL devtunnel) or UAT base host.
  static String get studentBaseUrl => isUat
      ? ApiConstantsUat.studentBaseUrl
      : 'https://$_localTunnelId-8085.inc1.devtunnels.ms';
 
  /// Classroom MS (LOCAL devtunnel) or UAT base host.
  static String get classroomBaseUrl => isUat
      ? ApiConstantsUat.classroomBaseUrl
      : 'https://$_localTunnelId-8082.inc1.devtunnels.ms';
 
  /// Staff MS (LOCAL devtunnel) or UAT base host.
  static String get staffBaseUrl => isUat
      ? ApiConstantsUat.staffBaseUrl
      : 'https://$_localTunnelId-8083.inc1.devtunnels.ms';
 
  /// School / organization MS (LOCAL devtunnel) or UAT base host.
  static String get schoolMs => isUat
      ? ApiConstantsUat.schoolMs
      : 'https://$_localTunnelId-8081.inc1.devtunnels.ms';
 
  /// Attendance base (LOCAL devtunnel) or UAT base host.
  static String get attendanceBaseUrl => isUat
      ? ApiConstantsUat.attendanceBaseUrl
      : 'https://$_localTunnelId-8090.inc1.devtunnels.ms/attendance';
 
  /// Activity base (LOCAL devtunnel) or UAT base host.
  static String get activityBaseUrl => isUat
      ? ApiConstantsUat.activityBaseUrl
      : 'https://$_localTunnelId-8084.inc1.devtunnels.ms/wowcare-activity-ms';
 
  /// Document MS base (LOCAL devtunnel) or UAT base host.
  ///
  /// Root UAT constants may not define a dedicated document host; in that case we
  /// default to the main base URL.
 
  static String get documentMsBaseUrl => isUat
      ? ApiConstantsUat.documentMsBaseUrl
      : 'https://fitten-vallie-forthrightly.ngrok-free.dev/document-ms';
 
  static String get communicationBaseUrl => isUat
      ? ApiConstantsUat.communicationBaseUrl
      : 'https://qs176zl8-8089.inc1.devtunnels.ms';
 
  /// Resolves host for [microserviceKey] (see [ApiMicroservices]).
  static String baseUrlForMicroservice(String microserviceKey) {
    if (isUat) return ApiConstantsUat.baseUrlForMicroservice(microserviceKey);
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
      case ApiMicroservices.document:
        return documentMsBaseUrl;
      case ApiMicroservices.communication:
        return communicationBaseUrl;
      case ApiMicroservices.user:
      default:
        return baseUrl;
    }
  }
}





