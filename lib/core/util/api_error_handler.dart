import 'package:dio/dio.dart';

/// Centralised mapping of any error (Dio / network / technical exception) to a
/// safe, user-facing message. Raw exception text and stack traces are **never**
/// surfaced to the user — only friendly messages. Callers should log the raw
/// error separately for debugging.
class ApiErrorHandler {
  ApiErrorHandler._();

  static const String genericError = 'Something went wrong. Please try again.';
  static const String timeoutError =
      'Request timed out. Please check your connection and try again.';
  static const String networkError =
      'Unable to connect. Please check your internet connection and try again.';

  /// Extracts a user-friendly message from a [DioException] or any error.
  ///
  /// Priority: transport errors (timeout/offline) → API body `message` → HTTP
  /// status mapping → sanitized fallback. Always returns a safe message.
  static String extractErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return timeoutError;
        case DioExceptionType.connectionError:
          return networkError;
        case DioExceptionType.cancel:
          return 'Request was cancelled. Please try again.';
        case DioExceptionType.badCertificate:
          return 'Secure connection failed. Please try again later.';
        case DioExceptionType.unknown:
        case DioExceptionType.badResponse:
          break;
      }

      final status = error.response?.statusCode;

      // Only 4xx client errors carry a meaningful, user-facing backend message
      // (e.g. "Invalid credentials", "Email already exists", "OTP is incorrect").
      // 5xx server errors and framework faults must NEVER surface their response
      // body (e.g. Spring's "Internal Server Error", stack text) — fall through to
      // a generic message and leave the raw detail for the logs.
      if (status != null && status >= 400 && status < 500) {
        final bodyMessage = _messageFromBody(error.response?.data);
        if (bodyMessage != null) return bodyMessage;
      }

      // No usable body message → map by HTTP status code (5xx → generic).
      final byStatus = _messageForStatus(status);
      if (byStatus != null) return byStatus;

      // Last resort: sanitize whatever Dio produced.
      return sanitizeMessage(error.message ?? error.error?.toString() ?? '');
    }

    return sanitizeMessage(error?.toString() ?? '');
  }

  static String? _messageFromBody(dynamic data) {
    if (data is Map) {
      for (final key in const ['message', 'error', 'detail', 'title']) {
        final value = data[key];
        final s = value?.toString().trim() ?? '';
        if (s.isNotEmpty) return sanitizeMessage(s);
      }
    }
    return null;
  }

  static String? _messageForStatus(int? status) {
    if (status == null) return null;
    switch (status) {
      case 400:
      case 422:
        return 'Some of the information provided is invalid. Please check and try again.';
      case 401:
        return 'Your session has expired. Please sign in again.';
      case 403:
        return "You don't have permission to perform this action.";
      case 404:
        return 'The requested information could not be found.';
      case 408:
        return timeoutError;
      case 409:
        return 'This action conflicts with existing data. Please refresh and try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      default:
        if (status >= 500) {
          return 'Something went wrong on our end. Please try again in a moment.';
        }
        if (status >= 400) return genericError;
        return null;
    }
  }

  /// Turns ANY string — a clean backend message OR a raw exception/stack dump —
  /// into a safe, user-facing message. This is the last line of defence used at
  /// display time so raw `DioException […]` / `SocketException` / stack-trace
  /// text can never reach the user, even if a call site forgot to map it.
  static String sanitizeMessage(String? raw) {
    var s = (raw ?? '').trim();
    if (s.isEmpty) return genericError;

    // Keep only the first line — drop stack traces / "Error: …" tails.
    final newline = s.indexOf('\n');
    if (newline != -1) s = s.substring(0, newline).trim();

    // Strip "DioException [type]: " and "SomethingException: " prefixes.
    s = s.replaceFirst(RegExp(r'^DioException\s*\[[^\]]*\]\s*:\s*'), '').trim();
    s = s.replaceFirst(RegExp(r'^[_A-Za-z]*Exception:\s*'), '').trim();

    final lower = s.toLowerCase();

    if (lower.contains('timeout') || lower.contains('timed out')) {
      return timeoutError;
    }
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('network is unreachable') ||
        lower.contains('connection refused') ||
        lower.contains('connection closed') ||
        lower.contains('connection reset') ||
        lower.contains('handshakeexception') ||
        lower.contains('clientexception')) {
      return networkError;
    }

    // Anything still resembling an internal/technical dump → generic.
    if (s.isEmpty ||
        lower.contains('dioexception') ||
        lower.contains('status code of') ||
        lower.contains('validatestatus') ||
        lower.contains('requestoptions') ||
        lower.contains('this exception was thrown') ||
        lower.contains('is not a subtype') ||
        lower.contains('formatexception') ||
        lower.contains('rangeerror') ||
        lower.contains('nosuchmethod') ||
        lower.contains('stack trace') ||
        lower.startsWith('#0') ||
        s.contains('package:') ||
        s.length > 240) {
      return genericError;
    }

    return s;
  }

  /// Extracts a success message from an API response body, or [defaultMessage].
  static String extractSuccessMessage(
    dynamic responseData, {
    String defaultMessage = 'Operation completed successfully',
  }) {
    if (responseData is Map) {
      final message = responseData['message'];
      final s = message?.toString().trim() ?? '';
      if (s.isNotEmpty) return s;
    }
    return defaultMessage;
  }
}
