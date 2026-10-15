import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/utils/location_service.dart';
import 'package:wowcare/presentation/features/attendance/view_model/attendance_location_fix.dart';

final _fix = LocationPoint(
  latitude: 51.5007,
  longitude: -0.1246,
  accuracyMeters: 5,
  timestamp: DateTime(2026, 10, 12),
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

  test('a fix is logged as succeeded with no coordinates', () async {
    final location = await AttendanceLocationFix(
      location: () async => _fix,
    ).take();
    await settle();

    expect(location, same(_fix));
    final log = logs.single;
    expect(log.body, 'attendance.location_check.succeeded');
    expect(log.attributes.keys, isNot(contains('count')));
    expect(
      log.attributes.values.map((a) => '${a.value}'),
      isNot(contains(anyOf(contains('51.5'), contains('-0.12')))),
    );
  });

  test('no fix at all is logged as failed, unavailable', () async {
    final location = await AttendanceLocationFix(
      location: () async => null,
    ).take();
    await settle();

    expect(location, isNull);
    expect(logs.single.body, 'attendance.location_check.failed');
    expect(logs.single.attributes['failure']!.value, 'unavailable');
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
