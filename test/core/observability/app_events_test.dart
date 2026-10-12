import 'dart:async';
import 'dart:io';

import 'package:dartz/dartz.dart' show Either, Left, Right;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/core/observability/app_events.dart';

void main() {
  group('EventFailure.of', () {
    final request = RequestOptions(path: '/x');

    DioException withStatus(int status) => DioException.badResponse(
      statusCode: status,
      requestOptions: request,
      response: Response<dynamic>(requestOptions: request, statusCode: status),
    );

    test('buckets Dio errors by type and status', () {
      expect(
        EventFailure.of(
          DioException.connectionError(
            requestOptions: request,
            reason: 'offline',
          ),
        ),
        EventFailure.network,
      );
      expect(
        EventFailure.of(
          DioException.receiveTimeout(
            timeout: Duration.zero,
            requestOptions: request,
          ),
        ),
        EventFailure.timeout,
      );
      expect(
        EventFailure.of(
          DioException.requestCancelled(requestOptions: request, reason: null),
        ),
        EventFailure.cancelled,
      );
      expect(EventFailure.of(withStatus(401)), EventFailure.unauthorized);
      expect(EventFailure.of(withStatus(403)), EventFailure.forbidden);
      expect(EventFailure.of(withStatus(404)), EventFailure.notFound);
      expect(EventFailure.of(withStatus(422)), EventFailure.validation);
      expect(EventFailure.of(withStatus(503)), EventFailure.server);
    });

    test('buckets repository failures and plain errors', () {
      expect(EventFailure.of(const NetworkFailure()), EventFailure.network);
      expect(EventFailure.of(const ServerFailure()), EventFailure.server);
      expect(
        EventFailure.of(const ValidationFailure()),
        EventFailure.validation,
      );
      expect(
        EventFailure.of(const AuthorizationFailure()),
        EventFailure.forbidden,
      );
      expect(EventFailure.of(const SocketException('x')), EventFailure.network);
      expect(EventFailure.of(TimeoutException('x')), EventFailure.timeout);
      expect(EventFailure.of('Could not mark absent'), EventFailure.unknown);
      expect(EventFailure.of(null), EventFailure.unknown);
    });
  });

  group('AppEvents', () {
    final logs = <SentryLog>[];

    setUp(() async {
      logs.clear();
      await Sentry.init((options) {
        options
          ..dsn = 'https://key@o1.ingest.sentry.io/1'
          ..enableLogs = true
          ..transport = _DiscardingTransport()
          ..beforeSendLog = (log) {
            logs.add(log);
            return log;
          };
      });
    });

    tearDown(() => Sentry.close());

    // Logging is fire-and-forget; give it a moment to land.
    Future<void> settle() =>
        Future<void>.delayed(const Duration(milliseconds: 50));

    Map<String, Object?> attributesOf(SentryLog log) => {
      for (final key in const ['event', 'outcome', 'failure', 'count'])
        if (log.attributes.containsKey(key)) key: log.attributes[key]!.value,
    };

    test('a success is an info line named module.action.outcome', () async {
      AppEvents.succeeded(AppEvent.authLogin, count: 2, durationMs: 15);
      await settle();

      final log = logs.single;
      expect(log.body, 'auth.login.succeeded');
      expect(log.level, SentryLogLevel.info);
      expect(attributesOf(log), {
        'event': 'auth.login',
        'outcome': 'succeeded',
        'count': 2,
      });
      expect(log.attributes['duration_ms']!.value, 15);
    });

    test('a failure is a warning with the bucket, never the error', () async {
      AppEvents.failed(AppEvent.authLogin, const ServerFailure('bad pw'));
      await settle();

      final log = logs.single;
      expect(log.body, 'auth.login.failed');
      expect(log.level, SentryLogLevel.warn);
      expect(log.attributes['failure']!.value, 'server');
      expect(
        log.attributes.values.map((a) => '${a.value}'),
        isNot(contains(contains('bad pw'))),
      );
    });

    test('record takes an explicit outcome', () async {
      AppEvents.record(AppEvent.authSession, EventOutcome.expired);
      await settle();

      expect(logs.single.body, 'auth.session.expired');
    });

    test('track logs a success with its duration', () async {
      final result = await AppEvents.track(
        AppEvent.authLogout,
        () async => 7,
        count: 1,
      );
      await settle();

      expect(result, 7);
      expect(logs.single.body, 'auth.logout.succeeded');
      expect(logs.single.attributes['duration_ms']!.value, isA<int>());
    });

    test('track logs a throw as failed and rethrows it', () async {
      await expectLater(
        AppEvents.track<void>(
          AppEvent.authLogout,
          () => throw const SocketException('x'),
        ),
        throwsA(isA<SocketException>()),
      );
      await settle();

      expect(logs.single.body, 'auth.logout.failed');
      expect(logs.single.attributes['failure']!.value, 'network');
    });

    test('track reads a failed result through failureOf', () async {
      await AppEvents.track(
        AppEvent.authLogout,
        () async => false,
        failureOf: (ok) => ok ? null : EventFailure.server,
      );
      await settle();

      expect(logs.single.body, 'auth.logout.failed');
      expect(logs.single.attributes['failure']!.value, 'server');
    });

    test('leftFailure buckets a Left and passes a Right', () async {
      await AppEvents.track<Either<Failure, int>>(
        AppEvent.taskDelete,
        () async => const Left(NetworkFailure()),
        failureOf: AppEvents.leftFailure,
      );
      await AppEvents.track<Either<Failure, int>>(
        AppEvent.taskDelete,
        () async => const Right(1),
        failureOf: AppEvents.leftFailure,
      );
      await settle();

      expect(logs.map((log) => log.body), [
        'task.delete.failed',
        'task.delete.succeeded',
      ]);
      expect(logs.first.attributes['failure']!.value, 'network');
    });

    test('countOf reads the count from a successful result', () async {
      await AppEvents.track(
        AppEvent.schedulingShiftCreate,
        () async => [1, 2, 3],
        count: 1,
        countOf: (shifts) => shifts.length,
      );
      await settle();

      expect(logs.single.attributes['count']!.value, 3);
    });
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
