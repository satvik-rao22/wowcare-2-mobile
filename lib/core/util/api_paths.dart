import 'api_constants.dart';

class ApiPaths {
  ApiPaths._();

  // Auth
  static const String authLogin = '/api/v1/auth/login';
  static const String authLogout = '/api/v1/auth/logout';

  // School
  static const String schoolNamesByOrg = '/api/v1/schools/names-by-org';

  /// Helper to build a full URL from a relative path.
  static String url(String path) => '${ApiConstants.baseUrl}$path';

  /// Helper to build a full URL from a relative path with a custom base URL.
  static String urlWithBase(String path, String baseUrl) => '$baseUrl$path';
}

