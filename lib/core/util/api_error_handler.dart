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
      return error.message ?? 
             error.error?.toString() ?? 
             'An error occurred';
    }
    
    // For non-DioException errors, return toString()
    return error.toString();
  }

  /// Extracts success message from API response.
  /// 
  /// Returns the 'message' field from response data if it's a Map,
  /// otherwise returns a default success message.
  static String extractSuccessMessage(dynamic responseData, {String defaultMessage = 'Operation completed successfully'}) {
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

