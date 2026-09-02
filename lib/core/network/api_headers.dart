/// Auth header helper for API requests.
/// Use [authorizedJson] to build headers with Bearer token for authenticated APIs.
class ApiHeaders {
  ApiHeaders._();

  /// Basic JSON headers without authentication.
  static const Map<String, String> json = {
    'Content-Type': 'application/json',
    'accept': 'application/json',
  };

  /// JSON headers with Authorization Bearer token.
  /// Returns Content-Type, accept, and Authorization: Bearer {token} when token is non-empty.
  static Map<String, String> authorizedJson(String accessToken) {
    return {
      ...json,
      if (accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
    };
  }

  static Map<String, String> organizationAndSchool({
    required String organizationCode,
    required String schoolCode,
  }) {
    final org = organizationCode.trim();
    final school = schoolCode.trim();
    return {
      if (org.isNotEmpty) 'X-Organization-Code': org,
      if (school.isNotEmpty) 'X-School-Code': school,

    };
  }
}


