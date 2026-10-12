import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/domain/features/geofencing/entities/location_permission_level.dart';
import 'package:wowcare/domain/features/geofencing/repositories/geofencing_repository.dart';
import 'package:wowcare/domain/features/geofencing/usecases/request_location_permission_usecase.dart';

/// Answers the permission prompt with [level], or fails with [error].
class _FakeGeofencingRepository implements GeofencingRepository {
  LocationPermissionLevel level = LocationPermissionLevel.whileInUse;
  Object? error;

  @override
  Future<LocationPermissionLevel> requestLocationPermission() async {
    if (error != null) throw error!;
    return level;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

void main() {
  final logs = <SentryLog>[];
  late _FakeGeofencingRepository repository;

  setUp(() async {
    logs.clear();
    repository = _FakeGeofencingRepository();
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

  test(
    'any granted level succeeds, any denial is a permission failure',
    () async {
      final useCase = RequestLocationPermissionUseCase(repository);
      const levels = [
        LocationPermissionLevel.whileInUse,
        LocationPermissionLevel.always,
        LocationPermissionLevel.denied,
        LocationPermissionLevel.permanentlyDenied,
      ];

      for (final level in levels) {
        repository.level = level;
        expect(await useCase(), level);
      }
      await settle();

      expect(logs.map((log) => log.body), [
        'geofence.permission_request.succeeded',
        'geofence.permission_request.succeeded',
        'geofence.permission_request.failed',
        'geofence.permission_request.failed',
      ]);
      expect(logs.map((log) => log.attributes['failure']?.value), [
        null,
        null,
        'permission',
        'permission',
      ]);
    },
  );

  test('a request that throws is rethrown and logged failed', () async {
    final error = StateError('plugin missing');
    repository.error = error;

    await expectLater(
      RequestLocationPermissionUseCase(repository)(),
      throwsA(same(error)),
    );
    await settle();

    expect(logs.single.body, 'geofence.permission_request.failed');
    expect(logs.single.attributes['failure']!.value, 'unknown');
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
