import 'package:dio/dio.dart';

/// Common utility to extract error and success messages from API responses.
/// Always extracts the 'message' field from API response JSON.
class ApiErrorHandler {
  ApiErrorHandler._();

  /// Extracts error message from DioException or any exception.
  ///
  /// Priority:
  /// 1. API response body's 'message' field (if response.data is Map)
  /// 2. DioException's error message
  /// 3. Exception's toString()
  static String extractErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Request timed out. Please check your connection and try again.';
        case DioExceptionType.connectionError:
          return 'Unable to connect to server. Please check your internet connection.';
        case DioExceptionType.cancel:
          return 'Request was cancelled. Please try again.';
        case DioExceptionType.badCertificate:
          return 'Secure connection failed. Please try again later.';
        case DioExceptionType.unknown:
        case DioExceptionType.badResponse:
          break;
      }

      // Try to get message from API response body first
      final responseData = error.response?.data;
      if (responseData is Map<String, dynamic>) {
        // Check for 'message' field in response
        if (responseData.containsKey('message')) {
          final message = responseData['message'];
          if (message != null && message.toString().isNotEmpty) {
            return message.toString();
          }
        }
        // Fallback to 'error' field if 'message' doesn't exist
        if (responseData.containsKey('error')) {
          final errorMsg = responseData['error'];
          if (errorMsg != null && errorMsg.toString().isNotEmpty) {
            return errorMsg.toString();
          }
        }
      }

      // If no message in response body, use DioException's message or error
      final fallback =
          error.message ?? error.error?.toString() ?? 'An error occurred';
      return _sanitizeFallbackMessage(fallback);
    }

    // For non-DioException errors, return toString()
    return _sanitizeFallbackMessage(error.toString());
  }

  static String _sanitizeFallbackMessage(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('timeout')) {
      return 'Request timed out. Please check your connection and try again.';
    }
    if (lower.contains('socketexception') ||
        lower.contains('network is unreachable')) {
      return 'Unable to connect to server. Please check your internet connection.';
    }
    if (lower.contains('dioexception')) {
      return 'Something went wrong while communicating with the server. Please try again.';
    }
    return raw.replaceFirst('Exception: ', '').trim();
  }

  /// Extracts success message from API response.
  ///
  /// Returns the 'message' field from response data if it's a Map,
  /// otherwise returns a default success message.
  static String extractSuccessMessage(
    dynamic responseData, {
    String defaultMessage = 'Operation completed successfully',
  }) {
    if (responseData is Map<String, dynamic>) {
      if (responseData.containsKey('message')) {
        final message = responseData['message'];
        if (message != null && message.toString().isNotEmpty) {
          return message.toString();
        }
      }
    }
    return defaultMessage;
  }
}
