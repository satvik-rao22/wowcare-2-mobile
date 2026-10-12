import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/domain/features/staff_classroom/repositories/staff_classroom_repository.dart';
import 'package:wowcare/domain/features/staff_classroom/usecases/assign_staff_to_classroom_usecase.dart';

class _FakeStaffClassroomRepository implements StaffClassroomRepository {
  Object? error;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return error == null ? Future.value('ok') : Future<String>.error(error!);
  }
}

void main() {
  final logs = <SentryLog>[];
  late _FakeStaffClassroomRepository repo;

  setUp(() async {
    logs.clear();
    repo = _FakeStaffClassroomRepository();
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

  void expectNoCodes() {
    for (final log in logs) {
      expect(
        log.attributes.values.map((a) => '${a.value}'),
        isNot(contains(anyOf('SCH-1', 'CLS-1', 'STF-1', 'STF-2'))),
      );
    }
  }

  test('assign logs the number of staff and no codes', () async {
    await AssignStaffToClassroomUseCase(repo)(
      schoolCode: 'SCH-1',
      classroomCode: 'CLS-1',
      staffCodes: const ['STF-1', 'STF-2'],
    );
    await settle();

    expect(logs.single.body, 'staff.classroom_assign.succeeded');
    expect(logs.single.attributes['count']!.value, 2);
    expectNoCodes();
  });

  test('a failure keeps its bucket although the use case throws a '
      'message', () async {
    final request = RequestOptions(path: '/x');
    repo.error = DioException.badResponse(
      statusCode: 401,
      requestOptions: request,
      response: Response<dynamic>(requestOptions: request, statusCode: 401),
    );

    await expectLater(
      AssignStaffToClassroomUseCase(repo)(
        schoolCode: 'SCH-1',
        classroomCode: 'CLS-1',
        staffCodes: const ['STF-1'],
      ),
      throwsA(isA<String>()),
    );
    await settle();

    expect(logs.single.body, 'staff.classroom_assign.failed');
    expect(logs.single.attributes['failure']!.value, 'unauthorized');
    expect(logs.single.attributes['count']!.value, 1);
    expectNoCodes();
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
