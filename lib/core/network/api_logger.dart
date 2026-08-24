import 'dart:convert';
import 'package:dio/dio.dart';
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

  static bool _isExpectedStatusCode(int? statusCode) {
    if (statusCode == null) return false;
    return statusCode >= 400 && statusCode < 500;
  }

  static bool _isExpectedDioError(Object error) {
    if (error is DioException) {
      return error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.cancel ||
          error.type == DioExceptionType.connectionError;
    }
    return false;
  }

  static void logError({
    required String url,
    required String method,
    String? type,
    String? message,
    int? statusCode,
    dynamic errorData,
    DioException? dioError,
    StackTrace? stackTrace,
  }) {
    AppLogger.c('═══════════════════════════════════════════════════════');
    AppLogger.c('🔴 API ERROR');
    AppLogger.c('Method: $method');
    AppLogger.c('URL: $url');
    if (type != null) {
      AppLogger.c('Error Type: $type');
    }
    if (message != null) {
      AppLogger.c('Error Message: $message');
    }
    if (statusCode != null) {
      AppLogger.c('Status Code: $statusCode');
    }
    if (errorData != null) {
      final String errorString = _stringify(errorData);
      _printInChunks('Error Response Data: $errorString', isError: true);
    }
    AppLogger.c('═══════════════════════════════════════════════════════');

    if (!_isExpectedStatusCode(statusCode)) {
      AppLogger.e(
        'Unexpected API Error: $method $url',
        dioError ?? 'Status: $statusCode, Message: $message',
        stackTrace,
      );
    }
  }

  static void logUnexpectedError({
    required String url,
    required String method,
    required Object error,
    StackTrace? stackTrace,
  }) {
    AppLogger.c('═══════════════════════════════════════════════════════');
    AppLogger.c('🔴 API UNEXPECTED ERROR');
    AppLogger.c('Method: $method');
    AppLogger.c('URL: $url');
    AppLogger.c('Error: $error');
    if (stackTrace != null) {
      AppLogger.c('Stack Trace: $stackTrace');
    }
    AppLogger.c('═══════════════════════════════════════════════════════');

    if (!_isExpectedDioError(error)) {
      AppLogger.e(
        'Unexpected API Failure: $method $url',
        error,
        stackTrace,
      );
    }
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
  static void _printInChunks(String text, {int chunkSize = 800, bool isError = false}) {
    if (text.length <= chunkSize) {
      isError ? AppLogger.c(text) : AppLogger.d(text);
      return;
    }

    var start = 0;
    while (start < text.length) {
      final end = (start + chunkSize < text.length)
          ? start + chunkSize
          : text.length;
      final chunk = text.substring(start, end);
      isError ? AppLogger.c(chunk) : AppLogger.d(chunk);
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
