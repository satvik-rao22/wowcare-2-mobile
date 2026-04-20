import 'dart:convert';
import 'package:wowcare/core/util/logger_service.dart';

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
    AppLogger.d('═══════════════════════════════════════════════════════');
    AppLogger.d('🔵 API REQUEST');
    AppLogger.d('Method: $method');

    // URL already includes query parameters from Dio (options.uri),
    // so just log it as-is to avoid duplicating the query string.
    AppLogger.d('URL: $url');

    if (queryParameters != null && queryParameters.isNotEmpty) {
      final String queryString = _stringify(queryParameters);
      AppLogger.d('Query Parameters: $queryString');
    }

    if (headers != null) {
      // Print headers line-by-line to avoid logcat truncation on long tokens.
      // ignore: avoid_print
      print('Headers:');
      headers.forEach((key, value) {
        final normalizedKey = key.toLowerCase();
        final displayValue = normalizedKey == 'authorization'
            ? _maskToken(value?.toString() ?? '')
            : (value?.toString() ?? '');
        _printInChunks('  $key: $displayValue');
      });
    }
    if (body != null) {
      final String bodyString = _stringify(body);
      AppLogger.d('Body: $bodyString');
    }
    AppLogger.d('═══════════════════════════════════════════════════════');
  }

  static void logResponse({
    required String url,
    required String method,
    Map<String, dynamic>? queryParameters,
    int? statusCode,
    dynamic data,
  }) {
    AppLogger.d('═══════════════════════════════════════════════════════');
    AppLogger.d('🟢 API RESPONSE');
    AppLogger.d('Method: $method');

    // URL already includes query parameters from Dio (requestOptions.uri),
    // so just log it as-is to avoid duplicating the query string.
    AppLogger.d('URL: $url');
    AppLogger.d('Status Code: $statusCode');
    if (data != null) {
      final String dataString = _stringify(data);
      _printInChunks('Response Data: $dataString');
    } else {
      AppLogger.d('Response Data: null');
    }
    AppLogger.d('═══════════════════════════════════════════════════════');
  }

  static void logError({
    required String url,
    required String method,
    String? type,
    String? message,
    int? statusCode,
    dynamic errorData,
  }) {
    AppLogger.e('═══════════════════════════════════════════════════════');
    AppLogger.e('🔴 API ERROR');
    AppLogger.e('Method: $method');
    AppLogger.e('URL: $url');
    if (type != null) {
      AppLogger.e('Error Type: $type');
    }
    if (message != null) {
      AppLogger.e('Error Message: $message');
    }
    if (statusCode != null) {
      AppLogger.e('Status Code: $statusCode');
    }
    if (errorData != null) {
      final String errorString = _stringify(errorData);
      _printInChunks('Error Response Data: $errorString');
    }
    AppLogger.e('═══════════════════════════════════════════════════════');
  }

  static void logUnexpectedError({
    required String url,
    required String method,
    required Object error,
    StackTrace? stackTrace,
  }) {
    AppLogger.e('═══════════════════════════════════════════════════════');
    AppLogger.e('🔴 API UNEXPECTED ERROR');
    AppLogger.e('Method: $method');
    AppLogger.e('URL: $url');
    AppLogger.e('Error: $error');
    if (stackTrace != null) {
      AppLogger.e('Stack Trace: $stackTrace');
    }
    AppLogger.e('═══════════════════════════════════════════════════════');
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
      AppLogger.d(text);
      return;
    }

    var start = 0;
    while (start < text.length) {
      final end = (start + chunkSize < text.length)
          ? start + chunkSize
          : text.length;
      AppLogger.d(text.substring(start, end));
      start = end;
    }
  }

  static String _maskToken(String token) {
    if (token.isEmpty) return token;
    const prefix = 'Bearer ';
    if (!token.startsWith(prefix)) return token;
    final raw = token.substring(prefix.length);
    if (raw.length <= 16) return '$prefix***';
    return '$prefix${raw.substring(0, 8)}...${raw.substring(raw.length - 8)}';
  }
}
