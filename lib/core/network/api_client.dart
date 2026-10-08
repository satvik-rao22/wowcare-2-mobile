import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/core/observability/telemetry_http.dart';

import 'api_logger.dart';

class ApiClient {
  ApiClient({
    required String baseUrl,
    List<Interceptor>? interceptors,

    /// Automatic cookie jar — mirrors the web clients' `credentials:
    /// 'include'`: the browser (here, this jar) captures `Set-Cookie` on
    /// every response and re-attaches matching cookies on every subsequent
    /// request to the same host, transparently. This is what lets
    /// `/auth/refresh` receive the refresh-token cookie the same way
    /// `/auth/login` set it, without any code reading or constructing a
    /// `Cookie:` header by hand. Passed in (rather than created here) so
    /// callers can give it a persistent, disk-backed [CookieJar] — an
    /// in-memory jar would lose the session on every cold start.
    CookieJar? cookieJar,

    /// Interceptors that need a reference to the [Dio] they're attached to —
    /// e.g. one that replays a request after refreshing the access token.
    /// Added alongside [interceptors], i.e. still BEFORE the logging wrapper.
    List<Interceptor> Function(Dio dio)? interceptorsBuilder,
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

    // Cookie manager goes FIRST — it has to see every response's raw
    // Set-Cookie (including on /auth/login and /auth/refresh) and attach
    // cookies to every outgoing request before any other interceptor (auth
    // headers, logging) touches them.
    if (cookieJar != null) {
      _dio.interceptors.add(CookieManager(cookieJar));
    }

    // Add custom interceptors FIRST (e.g., AuthInterceptor) so they run before logging
    if (interceptors != null && interceptors.isNotEmpty) {
      _dio.interceptors.addAll(interceptors);
    }
    if (interceptorsBuilder != null) {
      _dio.interceptors.addAll(interceptorsBuilder(_dio));
    }

    // Global logging interceptor added AFTER auth interceptors
    // This ensures Authorization header is logged since it's added by AuthInterceptor.
    //
    // Debug builds ONLY: this interceptor logs full request/response bodies and
    // headers (including Authorization). Never register it in release/profile —
    // doing so would push tokens, PINs and PII through the logging pipeline in
    // production. AppLogger already no-ops these sinks in release, but we also
    // skip building the payloads entirely here.
    if (kDebugMode) {
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
              dioError: error,
              stackTrace: error.stackTrace,
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

    // Last: Sentry wraps the adapter and transformer as configured above.
    TelemetryHttp.instrument(_dio);
  }

  late final Dio _dio;

  Dio get client => _dio;
}


