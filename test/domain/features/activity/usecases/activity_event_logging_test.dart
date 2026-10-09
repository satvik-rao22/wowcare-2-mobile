import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';
import 'package:wowcare/domain/features/activity/usecases/approve_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/create_activity_usecase.dart';

class _FakeActivityRepository implements ActivityRepository {
  Object? error;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return error == null ? Future.value('ok') : Future<String>.error(error!);
  }
}

void main() {
  final logs = <SentryLog>[];
  late _FakeActivityRepository repo;

  setUp(() async {
    logs.clear();
    repo = _FakeActivityRepository();
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

  test('create logs the student count', () async {
    await CreateActivityUseCase(repo)(
      activityTypeCode: 'NAP',
      classroomCode: 'CLS-1',
      studentCodes: const ['STU-1', 'STU-2'],
      staffCode: 'STF-1',
      schoolCode: 'SCH-1',
      organizationCode: 'ORG-1',
      activityDate: '2026-10-09',
      description: 'nap',
    );
    await settle();

    expect(logs.single.body, 'activity.create.succeeded');
    expect(logs.single.attributes['count']!.value, 2);
  });

  test(
    'a failure keeps its bucket although the use case throws a message',
    () async {
      final request = RequestOptions(path: '/x');
      repo.error = DioException.badResponse(
        statusCode: 403,
        requestOptions: request,
        response: Response<dynamic>(requestOptions: request, statusCode: 403),
      );

      await expectLater(
        ApproveActivityUseCase(repo)(code: 'ACT-1'),
        throwsA(isA<String>()),
      );
      await settle();

      expect(logs.single.body, 'activity.approve.failed');
      expect(logs.single.attributes['failure']!.value, 'forbidden');
    },
  );
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
