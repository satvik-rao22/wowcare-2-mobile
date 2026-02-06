class ApiHeaders {
  ApiHeaders._();

  /// Basic JSON headers without authentication.
  static const Map<String, String> json = {
    'Content-Type': 'application/json',
    'accept': 'application/json',
  };

  /// JSON headers with Authorization bearer token.
  static Map<String, String> authorizedJson(String accessToken) {
    return {
      ...json,
      if (accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
    };
  }
}


