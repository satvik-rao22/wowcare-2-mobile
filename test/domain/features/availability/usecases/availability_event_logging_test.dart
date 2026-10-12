import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/domain/features/availability/entities/individual_movement.dart';
import 'package:wowcare/domain/features/availability/repositories/availability_repository.dart';
import 'package:wowcare/domain/features/availability/usecases/create_individual_movement_usecase.dart';
import 'package:wowcare/domain/features/availability/usecases/delete_individual_movement_usecase.dart';
import 'package:wowcare/domain/features/availability/usecases/transition_individual_movement_status_usecase.dart';

class _FakeAvailabilityRepository implements AvailabilityRepository {
  Object? error;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return error == null ? Future.value('ok') : Future<String>.error(error!);
  }
}

void main() {
  final logs = <SentryLog>[];
  late _FakeAvailabilityRepository repo;

  setUp(() async {
    logs.clear();
    repo = _FakeAvailabilityRepository();
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

  void expectNoPersonalData() {
    for (final log in logs) {
      // The SDK adds its own `os.*` and `sentry.*` attributes.
      expect(
        log.attributes.keys.where(
          (key) => !key.startsWith('os.') && !key.startsWith('sentry.'),
        ),
        everyElement(
          isIn(const ['event', 'outcome', 'failure', 'count', 'duration_ms']),
        ),
      );
      expect(
        log.attributes.values.map((a) => '${a.value}'),
        isNot(
          contains(
            anyOf('STU-1', 'CLS-1', 'CLS-2', 'SCH-1', 'ORG-1', 'private note'),
          ),
        ),
      );
    }
  }

  test('create logs success and nothing about the student', () async {
    final message = await CreateIndividualMovementUseCase(repo)(
      schoolCode: 'SCH-1',
      organizationCode: 'ORG-1',
      studentCode: 'STU-1',
      movementType: IndividualMovementType.moveToNextClassroom,
      fromClassroomCode: 'CLS-1',
      toClassroomCode: 'CLS-2',
      movementDate: DateTime(2026, 10, 12),
      comment: 'private note',
    );
    await settle();

    expect(message, 'ok');
    expect(logs.single.body, 'availability.movement_create.succeeded');
    expect(logs.single.attributes.containsKey('count'), isFalse);
    expectNoPersonalData();
  });

  test('a failure keeps its bucket although the use case throws a '
      'message', () async {
    final request = RequestOptions(path: '/x');
    repo.error = DioException.badResponse(
      statusCode: 404,
      requestOptions: request,
      response: Response<dynamic>(requestOptions: request, statusCode: 404),
    );

    await expectLater(
      DeleteIndividualMovementUseCase(repo)(id: 7),
      throwsA(isA<String>()),
    );
    await settle();

    expect(logs.single.body, 'availability.movement_delete.failed');
    expect(logs.single.attributes['failure']!.value, 'notFound');
    expectNoPersonalData();
  });

  test('a status change logs its own event', () async {
    await TransitionIndividualMovementStatusUseCase(repo)(
      id: 7,
      status: IndividualMovementWorkflowStatus.confirmed,
      comment: 'private note',
    );
    await settle();

    expect(logs.single.body, 'availability.movement_status_change.succeeded');
    expectNoPersonalData();
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
