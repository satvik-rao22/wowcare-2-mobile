import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/staff/entities/create_school_user_result.dart';
import 'package:wowcare/domain/features/staff/entities/school_user.dart';
import 'package:wowcare/domain/features/staff/entities/staff_important_date.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/activate_school_user_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/create_school_user_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/deactivate_school_user_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/delete_staff_document_usecase.dart';
import 'package:wowcare/domain/features/staff/usecases/update_important_dates_usecase.dart';

const _created = CreateSchoolUserResult(
  message: 'ok',
  user: SchoolUser(
    userCode: 'USR-1',
    firstName: 'Jane',
    lastName: 'Doe',
    displayName: 'Jane Doe',
    mobile: '5550100',
    email: 'jane@example.com',
    organizationCode: 'ORG-1',
    schoolCode: 'SCH-1',
    role: 'staff',
    designation: 'Teacher',
  ),
);

class _FakeStaffRepository implements StaffRepository {
  Object? error;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #createStaffUser ||
        invocation.memberName == #createSchoolAdminUser) {
      return error == null
          ? Future.value(_created)
          : Future<CreateSchoolUserResult>.error(error!);
    }
    return error == null ? Future.value('ok') : Future<String>.error(error!);
  }
}

DioException _status(int code) {
  final request = RequestOptions(path: '/x');
  return DioException.badResponse(
    statusCode: code,
    requestOptions: request,
    response: Response<dynamic>(requestOptions: request, statusCode: code),
  );
}

void main() {
  final logs = <SentryLog>[];
  late _FakeStaffRepository repo;

  setUp(() async {
    logs.clear();
    repo = _FakeStaffRepository();
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

  /// An event carries a fixed set of attributes and none of the identifiers
  /// the use cases were called with.
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
            anyOf(
              'USR-1',
              'ORG-1',
              'SCH-1',
              'STF-1',
              'DOC-1',
              'jane@example.com',
              'Jane',
            ),
          ),
        ),
      );
    }
  }

  test('activate logs success and nothing about the user', () async {
    await ActivateSchoolUserUseCase(repo)(
      userCode: 'USR-1',
      organizationCode: 'ORG-1',
      schoolCode: 'SCH-1',
      role: 'staff',
    );
    await settle();

    expect(logs.single.body, 'staff.activate.succeeded');
    expect(logs.single.attributes.containsKey('count'), isFalse);
    expectNoPersonalData();
  });

  test('a thrown error keeps its type and is bucketed', () async {
    repo.error = _status(403);

    await expectLater(
      DeactivateSchoolUserUseCase(repo)(
        userCode: 'USR-1',
        organizationCode: 'ORG-1',
        schoolCode: 'SCH-1',
        role: 'staff',
      ),
      throwsA(isA<DioException>()),
    );
    await settle();

    expect(logs.single.body, 'staff.deactivate.failed');
    expect(logs.single.attributes['failure']!.value, 'forbidden');
    expectNoPersonalData();
  });

  test('create logs one event for the admin path and one for staff', () async {
    final useCase = CreateSchoolUserUseCase(repo);

    Future<Either<Failure, CreateSchoolUserResult>> create({
      required bool isAdmin,
    }) => useCase(
      isAdmin: isAdmin,
      firstName: 'Jane',
      lastName: 'Doe',
      displayName: 'Jane Doe',
      mobile: '5550100',
      email: 'jane@example.com',
      organizationCode: 'ORG-1',
      schoolCode: 'SCH-1',
      role: 'staff',
      designation: 'Teacher',
    );

    expect((await create(isAdmin: true)).isRight(), isTrue);
    expect((await create(isAdmin: false)).isRight(), isTrue);
    await settle();

    expect(logs.map((log) => log.body), [
      'staff.create.succeeded',
      'staff.create.succeeded',
    ]);
    expectNoPersonalData();
  });

  test('create keeps returning a Left and buckets the raw error', () async {
    repo.error = _status(409);

    final result = await CreateSchoolUserUseCase(repo)(
      isAdmin: false,
      firstName: 'Jane',
      lastName: 'Doe',
      displayName: 'Jane Doe',
      mobile: '5550100',
      email: 'jane@example.com',
      organizationCode: 'ORG-1',
      schoolCode: 'SCH-1',
      role: 'staff',
      designation: 'Teacher',
    );
    await settle();

    expect(result.isLeft(), isTrue);
    expect(logs.single.body, 'staff.create.failed');
    expect(logs.single.attributes['failure']!.value, 'validation');
    expectNoPersonalData();
  });

  test('important dates map a network error to a Left and a bucket', () async {
    repo.error = DioException.connectionError(
      requestOptions: RequestOptions(path: '/x'),
      reason: 'offline',
    );

    final result = await UpdateImportantDatesUseCase(repo)(
      staffCode: 'STF-1',
      dates: const [
        StaffImportantDate(
          importantDateType: 'BIRTHDAY',
          dueDate: '2026-10-12',
        ),
      ],
    );
    await settle();

    expect(result.isLeft(), isTrue);
    expect(logs.single.body, 'staff.important_dates_update.failed');
    expect(logs.single.attributes['failure']!.value, 'network');
    expectNoPersonalData();
  });

  test('document delete logs a not-found bucket', () async {
    repo.error = _status(404);

    final result = await DeleteStaffDocumentUseCase(repo)(
      documentUuid: 'DOC-1',
      staffCode: 'STF-1',
    );
    await settle();

    expect(result.isLeft(), isTrue);
    expect(logs.single.body, 'staff.document_delete.failed');
    expect(logs.single.attributes['failure']!.value, 'notFound');
    expectNoPersonalData();
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
