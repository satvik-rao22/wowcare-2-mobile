import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_location_fix.dart';

final _fix = Position(
  latitude: 51.5007,
  longitude: -0.1246,
  timestamp: DateTime(2026, 10, 12),
  accuracy: 5,
  altitude: 0,
  altitudeAccuracy: 0,
  heading: 0,
  headingAccuracy: 0,
  speed: 0,
  speedAccuracy: 0,
);

void main() {
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

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  Future<Position?> take({
    required Future<Position> Function() current,
    Future<Position?> Function()? lastKnown,
  }) {
    return AttendanceLocationFix(
      currentPosition: current,
      lastKnownPosition: lastKnown ?? () async => null,
    ).take(caller: 'Test');
  }

  test('a fix is logged as succeeded with no coordinates', () async {
    final position = await take(current: () async => _fix);
    await settle();

    expect(position, same(_fix));
    final log = logs.single;
    expect(log.body, 'attendance.location_check.succeeded');
    expect(log.attributes.keys, isNot(contains('count')));
    expect(
      log.attributes.values.map((a) => '${a.value}'),
      isNot(contains(anyOf(contains('51.5'), contains('-0.12')))),
    );
  });

  test('a last known position still counts as a fix', () async {
    final position = await take(
      current: () => Future.error(TimeoutException('no fix')),
      lastKnown: () async => _fix,
    );
    await settle();

    expect(position, same(_fix));
    expect(logs.single.body, 'attendance.location_check.succeeded');
  });

  group('falling back without a location', () {
    Future<String> failureFor(Object error) async {
      final position = await take(current: () => Future.error(error));
      await settle();

      expect(position, isNull);
      expect(logs.single.body, 'attendance.location_check.failed');
      return '${logs.single.attributes['failure']!.value}';
    }

    test('permission denied', () async {
      expect(
        await failureFor(const PermissionDeniedException('denied')),
        'permission',
      );
    });

    test('location services off', () async {
      expect(
        await failureFor(const LocationServiceDisabledException()),
        'unavailable',
      );
    });

    test('the 10 s time limit', () async {
      expect(await failureFor(TimeoutException('no fix')), 'timeout');
    });

    test('anything else', () async {
      expect(await failureFor(StateError('plugin')), 'unknown');
    });

    test('the last known lookup throwing too, never escapes', () async {
      final position = await take(
        current: () => Future.error(const PermissionDeniedException('denied')),
        lastKnown: () => Future.error(const PermissionDeniedException('x')),
      );
      await settle();

      expect(position, isNull);
      expect(logs.single.attributes['failure']!.value, 'permission');
    });
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
