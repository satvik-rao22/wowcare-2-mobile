import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/domain/features/activity/entities/recovered_media.dart';
import 'package:wowcare/domain/features/activity/repositories/activity_repository.dart';
import 'package:wowcare/domain/features/activity/repositories/lost_media_repository.dart';
import 'package:wowcare/domain/features/activity/usecases/approve_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/create_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/delete_activity_usecase.dart';
import 'package:wowcare/domain/features/activity/usecases/retrieve_lost_media_usecase.dart';

class _FakeActivityRepository implements ActivityRepository {
  Object? error;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return error == null ? Future.value('ok') : Future<String>.error(error!);
  }
}

class _FakeLostMediaRepository implements LostMediaRepository {
  _FakeLostMediaRepository(this.recovered);

  final RecoveredMedia recovered;

  @override
  Future<RecoveredMedia> retrieveLostMedia() async => recovered;
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

  test('delete logs its outcome and not the activity code', () async {
    await DeleteActivityUseCase(repo)(code: 'ACT-9');
    await settle();

    final log = logs.single;
    expect(log.body, 'activity.delete.succeeded');
    expect(log.attributes['count'], isNull);
    expect(
      log.attributes.values.map((a) => '${a.value}'),
      isNot(contains('ACT-9')),
    );
  });

  test('a delete the server cannot find is bucketed notFound', () async {
    final request = RequestOptions(path: '/x');
    repo.error = DioException.badResponse(
      statusCode: 404,
      requestOptions: request,
      response: Response<dynamic>(requestOptions: request, statusCode: 404),
    );

    await expectLater(
      DeleteActivityUseCase(repo)(code: 'ACT-9'),
      throwsA(isA<String>()),
    );
    await settle();

    expect(logs.single.body, 'activity.delete.failed');
    expect(logs.single.attributes['failure']!.value, 'notFound');
  });

  group('lost media recovery', () {
    test('logs the recovered item count and no file path', () async {
      const recovered = RecoveredMedia(
        type: RecoveredMediaType.image,
        filePaths: ['/data/cache/a.jpg', '/data/cache/b.jpg'],
      );

      final result = await RetrieveLostMediaUseCase(
        _FakeLostMediaRepository(recovered),
      )();
      await settle();

      expect(result, same(recovered));
      final log = logs.single;
      expect(log.body, 'activity.media_recover.succeeded');
      expect(log.attributes['count']!.value, 2);
      expect(
        log.attributes.values.map((a) => '${a.value}'),
        isNot(contains(startsWith('/data/'))),
      );
    });

    test('logs nothing when nothing was pending', () async {
      await RetrieveLostMediaUseCase(
        _FakeLostMediaRepository(RecoveredMedia.none),
      )();
      await settle();

      expect(logs, isEmpty);
    });

    test(
      'a capture the camera app lost is failed, without its message',
      () async {
        const recovered = RecoveredMedia(
          type: RecoveredMediaType.video,
          filePaths: [],
          errorMessage: 'camera crashed',
        );

        await RetrieveLostMediaUseCase(_FakeLostMediaRepository(recovered))();
        await settle();

        final log = logs.single;
        expect(log.body, 'activity.media_recover.failed');
        expect(log.attributes['failure']!.value, 'unknown');
        expect(
          log.attributes.values.map((a) => '${a.value}'),
          isNot(contains('camera crashed')),
        );
      },
    );
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
