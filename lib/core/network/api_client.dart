import 'package:dio/dio.dart';

import 'api_logger.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    List<Interceptor>? interceptors,
    Duration connectTimeout = const Duration(seconds: 20),
    Duration receiveTimeout = const Duration(seconds: 20),
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

    // Global logging interceptor
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
    if (interceptors != null && interceptors.isNotEmpty) {
      _dio.interceptors.addAll(interceptors);
    }
  }

  late final Dio _dio;

  Dio get client => _dio;
}


