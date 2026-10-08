import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_dio/sentry_dio.dart';
import 'package:sentry_flutter/sentry_flutter.dart' show SentryStatusCode;
import 'package:wowcare/core/observability/telemetry.dart';
import 'package:wowcare/core/observability/telemetry_config.dart';
import 'package:wowcare/core/observability/telemetry_redactor.dart';

/// Network coverage for the app's API client.
///
/// Only the single authenticated `ApiClient` Dio is instrumented. The bare
/// `Dio()` instances (the S3 presigned PUT, file downloads) are left alone on
/// purpose: their URLs carry signatures and their failures are already traced
/// by `MediaUploadTrace`.
abstract final class TelemetryHttp {
  TelemetryHttp._();

  /// Adds the write-request log and Sentry's Dio integration to [dio]. Call it
  /// after every other interceptor is in place: `addSentry` wraps the adapter
  /// and transformer as they are at that moment.
  ///
  /// Sentry then records a breadcrumb and a span per request, and reports
  /// 5xx responses as errors. 4xx are expected outcomes (validation, missing
  /// permission) and stay out of the issue stream; they still appear in the
  /// write-request log.
  static void instrument(
    Dio dio, {
    TelemetryConfig config = TelemetryConfig.fromBuild,
  }) {
    if (!config.isEnabled) return;
    dio.interceptors.add(ApiWriteLogInterceptor());
    dio.addSentry(
      captureFailedRequests: true,
      failedRequestStatusCodes: [SentryStatusCode.range(500, 599)],
    );
  }
}

/// Emits one structured log per POST, PUT, PATCH and DELETE: method, path
/// template, status and duration. Reads are left to the breadcrumbs, which
/// would otherwise drown the writes in volume.
///
/// The body is the method and path template, which is free of record codes.
/// Nothing from the request or response payload is read.
@visibleForTesting
class ApiWriteLogInterceptor extends Interceptor {
  static const Set<String> _writeMethods = {'POST', 'PUT', 'PATCH', 'DELETE'};
  static const String _startedAtKey = 'telemetry_started_at';

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra[_startedAtKey] = DateTime.now();
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    _log(response.requestOptions, response.statusCode);
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log(err.requestOptions, err.response?.statusCode, failure: err.type);
    handler.next(err);
  }

  void _log(RequestOptions options, int? status, {DioExceptionType? failure}) {
    final method = options.method.toUpperCase();
    if (!_writeMethods.contains(method)) return;
    final path = TelemetryRedactor.templatePath(options.uri.path);
    final startedAt = options.extra[_startedAtKey];
    final level = switch (status) {
      null || >= 500 => TelemetryLogLevel.error,
      >= 400 => TelemetryLogLevel.warn,
      _ => TelemetryLogLevel.info,
    };
    Telemetry.log(
      '$method $path',
      level: level,
      attributes: {
        'method': method,
        'path': path,
        if (status != null) 'status': status,
        if (startedAt is DateTime)
          'duration_ms': DateTime.now().difference(startedAt).inMilliseconds,
        // Only when there was no response at all: timeout, offline, cancel.
        if (status == null && failure != null) 'failure': failure.name,
      },
    );
  }
}
