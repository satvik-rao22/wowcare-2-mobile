import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/core/utils/app_console.dart';
import 'package:wowcare/core/utils/logger_service.dart';

/// Request, response and error logging for API calls.
///
/// In debug builds each call prints one block to the console through
/// [AppConsole]: blue for requests and successes, orange for 4xx, red for 5xx
/// and dropped connections, with the status and the time the call took. JSON
/// bodies are indented while they stay short enough to read.
///
/// Release builds print nothing. An error still leaves a Crashlytics log line,
/// and an unexpected one (not a 4xx, not a timeout or dropped connection) is
/// reported through [AppLogger.e], exactly as before.
class ApiLogger {
  ApiLogger._();

  static void logRequest({
    required String url,
    required String method,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
  }) {
    if (!kDebugMode) return;
    final block = StringBuffer('⇡ ${method.toUpperCase()} $url');
    if (queryParameters != null && queryParameters.isNotEmpty) {
      block.write('\nQuery: ${formatBody(queryParameters)}');
    }
    if (headers != null && headers.isNotEmpty) {
      block.write('\nHeaders:');
      headers.forEach((key, value) {
        block.write('\n  $key: ${maskHeader(key, value?.toString() ?? '')}');
      });
    }
    if (body != null) {
      block.write('\nBody: ${formatBody(body)}');
    }
    AppConsole.http(block.toString());
  }

  static void logResponse({
    required String url,
    required String method,
    Map<String, dynamic>? queryParameters,
    int? statusCode,
    dynamic data,
    Duration? elapsed,
  }) {
    if (!kDebugMode) return;
    final block = StringBuffer(
      '⇣ $statusCode ${method.toUpperCase()} $url${_took(elapsed)}',
    );
    block.write('\nData: ${data == null ? 'null' : formatBody(data)}');
    AppConsole.http(block.toString(), status: statusCode);
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
    Duration? elapsed,
  }) {
    final block = StringBuffer(
      '✕ ${statusCode ?? '---'} ${method.toUpperCase()} $url${_took(elapsed)}',
    );
    if (type != null) block.write('\nType: $type');
    if (message != null) block.write('\nMessage: $message');
    if (errorData != null) block.write('\nData: ${formatBody(errorData)}');
    _emitError(block.toString(), status: statusCode);

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
    Duration? elapsed,
  }) {
    final block = StringBuffer(
      '✕ --- ${method.toUpperCase()} $url${_took(elapsed)}',
    );
    block.write(
      error is DioException
          ? '\nType: ${error.type.name}\nMessage: ${error.message}'
          : '\nError: $error',
    );
    _emitError(block.toString(), failed: true);

    if (!_isExpectedDioError(error)) {
      AppLogger.e('Unexpected API Failure: $method $url', error, stackTrace);
    }
  }

  /// Debug: a red or orange console block. Release: the same text as a
  /// Crashlytics log line, which is what [AppLogger.c] did here before.
  static void _emitError(String block, {int? status, bool failed = false}) {
    if (kDebugMode) {
      AppConsole.http(block, status: status, failed: failed);
    } else {
      AppLogger.c(block);
    }
  }

  static String _took(Duration? elapsed) =>
      elapsed == null ? '' : '  (${elapsed.inMilliseconds} ms)';

  /// Bodies up to this many characters of JSON are indented; longer ones
  /// stay on one line, which [AppConsole] splits for logcat.
  static const int _indentLimit = 4000;

  /// Renders a request or response body for the console: JSON indented when
  /// short, form data as its field names and file sizes.
  @visibleForTesting
  static String formatBody(dynamic value) {
    if (value is String) return value;
    if (value is FormData) {
      final fields = value.fields.map((field) => field.key);
      final files = value.files.map(
        (file) =>
            '${file.key}: ${file.value.filename ?? 'file'} '
            '(${file.value.length} bytes)',
      );
      return 'FormData(fields: [${fields.join(', ')}], '
          'files: [${files.join(', ')}])';
    }
    try {
      final compact = jsonEncode(value);
      if (compact.length > _indentLimit) return compact;
      return '\n${const JsonEncoder.withIndent('  ').convert(value)}';
    } catch (_) {
      return value.toString();
    }
  }

  /// Shortens credentials so a console log never shows a usable one.
  @visibleForTesting
  static String maskHeader(String key, String value) {
    final name = key.toLowerCase();
    if (name == 'cookie' || name == 'set-cookie') {
      return value.isEmpty ? value : '***';
    }
    if (name != 'authorization' || value.isEmpty) return value;
    const prefix = 'Bearer ';
    if (!value.startsWith(prefix)) return '***';
    final raw = value.substring(prefix.length);
    if (raw.length <= 16) return '$prefix***';
    return '$prefix${raw.substring(0, 8)}...${raw.substring(raw.length - 8)}';
  }
}
