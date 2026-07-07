import 'package:dio/dio.dart';

import 'api_logger.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    List<Interceptor>? interceptors,
    // Long enough to tolerate slow dev tunnels / cold-started local
    // backends, but still bounded so the UI shows an error instead of a
    // frozen spinner forever when the server is genuinely unreachable.
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 30),
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        responseType: ResponseType.json,
        contentType: 'application/json',
      ),
    );

    // Add custom interceptors FIRST (e.g., AuthInterceptor) so they run before logging
    if (interceptors != null && interceptors.isNotEmpty) {
      _dio.interceptors.addAll(interceptors);
    }

    // Global logging interceptor added AFTER auth interceptors
    // This ensures Authorization header is logged since it's added by AuthInterceptor
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          ApiLogger.logRequest(
            url: options.uri.toString(),
            method: options.method,
            headers: options.headers.cast<String, dynamic>(),
            queryParameters:
                options.queryParameters.isEmpty ? null : options.queryParameters,
            body: options.data,
          );
          handler.next(options);
        },
        onResponse: (response, handler) {
          ApiLogger.logResponse(
            url: response.requestOptions.uri.toString(),
            method: response.requestOptions.method,
            queryParameters: response.requestOptions.queryParameters.isEmpty
                ? null
                : response.requestOptions.queryParameters,
            statusCode: response.statusCode,
            data: response.data,
          );
          handler.next(response);
        },
        onError: (error, handler) {
          final request = error.requestOptions;
          if (error.response != null) {
            ApiLogger.logError(
              url: request.uri.toString(),
              method: request.method,
              statusCode: error.response?.statusCode,
              message: error.message,
              errorData: error.response?.data,
            );
          } else {
            ApiLogger.logUnexpectedError(
              url: request.uri.toString(),
              method: request.method,
              error: error,
              stackTrace: error.stackTrace,
            );
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;

  Dio get client => _dio;
}


