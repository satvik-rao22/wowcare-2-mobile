import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/observability/telemetry_config.dart';
import 'package:wowcare/core/observability/telemetry_http.dart';

void main() {
  const dsn = 'https://key@o1.ingest.sentry.io/1';

  group('TelemetryHttp.instrument', () {
    test('leaves the Dio untouched when Sentry is off', () {
      final dio = Dio();
      final adapter = dio.httpClientAdapter;

      TelemetryHttp.instrument(
        dio,
        config: const TelemetryConfig(
          dsn: '',
          environment: 'DEV',
          isDebugBuild: false,
        ),
      );

      expect(dio.interceptors.whereType<ApiWriteLogInterceptor>(), isEmpty);
      expect(dio.httpClientAdapter, same(adapter));
    });

    test('adds the write log and wraps the adapter when Sentry is on', () {
      final dio = Dio();
      final adapter = dio.httpClientAdapter;

      TelemetryHttp.instrument(
        dio,
        config: const TelemetryConfig(
          dsn: dsn,
          environment: 'DEV',
          isDebugBuild: false,
        ),
      );

      expect(
        dio.interceptors.whereType<ApiWriteLogInterceptor>(),
        hasLength(1),
      );
      expect(dio.httpClientAdapter, isNot(same(adapter)));
    });
  });

  group('ApiWriteLogInterceptor', () {
    final logs = <SentryLog>[];

    setUp(() async {
      logs.clear();
      await Sentry.init((options) {
        options
          ..dsn = dsn
          ..enableLogs = true
          ..transport = _DiscardingTransport()
          ..beforeSendLog = (log) {
            logs.add(log);
            return log;
          };
      });
    });

    tearDown(() => Sentry.close());

    // The interceptor hands Sentry the log without awaiting it.
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 50));

    Dio dioReturning(HttpClientAdapter adapter) {
      return Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = adapter
        ..interceptors.add(ApiWriteLogInterceptor());
    }

    test('logs a write with the path template, status and duration', () async {
      final dio = dioReturning(_StatusAdapter(201));

      await dio.post<dynamic>(
        '/api/v1/events/EVT_99E594B6AC/rsvps',
        queryParameters: {'studentCode': 'STU-1'},
        data: {'note': 'secret'},
      );
      await settle();

      final log = logs.single;
      expect(log.body, 'POST /api/v1/events/{id}/rsvps');
      expect(log.level, SentryLogLevel.info);
      expect(log.attributes['method']!.value, 'POST');
      expect(log.attributes['path']!.value, '/api/v1/events/{id}/rsvps');
      expect(log.attributes['status']!.value, 201);
      expect(log.attributes['duration_ms']!.value, isA<int>());
      expect(log.attributes.containsKey('failure'), isFalse);
    });

    test('does not log reads', () async {
      final dio = dioReturning(_StatusAdapter(200));

      await dio.get<dynamic>('/api/v1/events');
      await settle();

      expect(logs, isEmpty);
    });

    test('logs a 4xx as a warning and a 5xx as an error', () async {
      await expectLater(
        dioReturning(_StatusAdapter(404)).delete<dynamic>('/api/v1/tasks/T1'),
        throwsA(isA<DioException>()),
      );
      await expectLater(
        dioReturning(_StatusAdapter(503)).patch<dynamic>('/api/v1/tasks/T1'),
        throwsA(isA<DioException>()),
      );
      await settle();

      expect(logs.map((log) => log.level), [
        SentryLogLevel.warn,
        SentryLogLevel.error,
      ]);
      expect(logs.map((log) => log.attributes['status']!.value), [404, 503]);
    });

    test('names the failure when no response came back', () async {
      final dio = dioReturning(_UnreachableAdapter());

      await expectLater(
        dio.put<dynamic>('/api/v1/tasks/T1'),
        throwsA(isA<DioException>()),
      );
      await settle();

      final log = logs.single;
      expect(log.level, SentryLogLevel.error);
      expect(log.attributes.containsKey('status'), isFalse);
      expect(log.attributes['failure']!.value, 'connectionError');
    });
  });
}

class _StatusAdapter implements HttpClientAdapter {
  _StatusAdapter(this.status);

  final int status;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromString(
      '{}',
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _UnreachableAdapter implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    throw DioException.connectionError(
      requestOptions: options,
      reason: 'offline',
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
