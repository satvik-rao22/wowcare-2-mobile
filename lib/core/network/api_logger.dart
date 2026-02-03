import 'dart:convert';

// Simple API logger to centralize request/response/error logging for all APIs.
class ApiLogger {
  ApiLogger._();

  static void logRequest({
    required String url,
    required String method,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) {
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════');
    // ignore: avoid_print
    print('🔵 API REQUEST');
    // ignore: avoid_print
    print('Method: $method');
    
    // URL already includes query parameters from Dio (options.uri),
    // so just log it as-is to avoid duplicating the query string.
    // ignore: avoid_print
    print('URL: $url');
    
    if (queryParameters != null && queryParameters.isNotEmpty) {
      final String queryString = _stringify(queryParameters);
      // ignore: avoid_print
      print('Query Parameters: $queryString');
    }
    
    if (headers != null) {
      // ignore: avoid_print
      print('Headers: $headers');
    }
    if (body != null) {
      final String bodyString = _stringify(body);
      // ignore: avoid_print
      print('Body: $bodyString');
    }
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════');
  }

  static void logResponse({
    required String url,
    required String method,
    Map<String, dynamic>? queryParameters,
    int? statusCode,
    dynamic data,
  }) {
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════');
    // ignore: avoid_print
    print('🟢 API RESPONSE');
    // ignore: avoid_print
    print('Method: $method');
    
    // URL already includes query parameters from Dio (requestOptions.uri),
    // so just log it as-is to avoid duplicating the query string.
    // ignore: avoid_print
    print('URL: $url');
    // ignore: avoid_print
    print('Status Code: $statusCode');
    if (data != null) {
      final String dataString = _stringify(data);
      _printInChunks('Response Data: $dataString');
    } else {
      // ignore: avoid_print
      print('Response Data: null');
    }
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════');
  }

  static void logError({
    required String url,
    required String method,
    String? type,
    String? message,
    int? statusCode,
    dynamic errorData,
  }) {
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════');
    // ignore: avoid_print
    print('🔴 API ERROR');
    // ignore: avoid_print
    print('Method: $method');
    // ignore: avoid_print
    print('URL: $url');
    if (type != null) {
      // ignore: avoid_print
      print('Error Type: $type');
    }
    if (message != null) {
      // ignore: avoid_print
      print('Error Message: $message');
    }
    if (statusCode != null) {
      // ignore: avoid_print
      print('Status Code: $statusCode');
    }
    if (errorData != null) {
      final String errorString = _stringify(errorData);
      _printInChunks('Error Response Data: $errorString');
    }
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════');
  }

  static void logUnexpectedError({
    required String url,
    required String method,
    required Object error,
    StackTrace? stackTrace,
  }) {
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════');
    // ignore: avoid_print
    print('🔴 API UNEXPECTED ERROR');
    // ignore: avoid_print
    print('Method: $method');
    // ignore: avoid_print
    print('URL: $url');
    // ignore: avoid_print
    print('Error: $error');
    if (stackTrace != null) {
      // ignore: avoid_print
      print('Stack Trace: $stackTrace');
    }
    // ignore: avoid_print
    print('═══════════════════════════════════════════════════════');
  }

  /// Safely converts any body/response object to a full JSON string when possible.
  static String _stringify(dynamic value) {
    try {
      // If it's already a String, return as is (assume it's what caller wants)
      if (value is String) return value;

      // If it's a Map/List or other JSON-encodable type, pretty-print as JSON
      return jsonEncode(value);
    } catch (_) {
      // Fallback to default toString if encoding fails
      return value.toString();
    }
  }

  /// Prints long strings in multiple chunks so that logcat does not truncate them.
  static void _printInChunks(String text, {int chunkSize = 800}) {
    if (text.length <= chunkSize) {
      // ignore: avoid_print
      print(text);
      return;
    }

    var start = 0;
    while (start < text.length) {
      final end = (start + chunkSize < text.length) ? start + chunkSize : text.length;
      // ignore: avoid_print
      print(text.substring(start, end));
      start = end;
    }
  }
}
