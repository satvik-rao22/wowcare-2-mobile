import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/student/entities/student_regular_schedule_input.dart';
import 'package:wowcare/domain/features/student/entities/update_guardian_request.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/add_pickup_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/add_student_document_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/add_student_sibling_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/change_guardian_pin_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/create_guardian_user_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/delete_guardian_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/delete_physician_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/delete_student_document_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/generate_guardian_pin_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/link_existing_guardian_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/resend_guardian_invite_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_guardian_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_regular_schedules_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_siblings_usecase.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_tags_usecase.dart';
import 'package:wowcare/domain/features/student_classroom/repositories/student_classroom_repository.dart';
import 'package:wowcare/domain/features/student_classroom/usecases/assign_students_to_classroom_usecase.dart';
import 'package:wowcare/domain/features/user_profile/entities/guardian_profile_update.dart';
import 'package:wowcare/domain/features/user_profile/repositories/user_profile_repository.dart';
import 'package:wowcare/domain/features/user_profile/usecases/update_guardian_profile_usecase.dart';

/// Succeeds with a value of the right type for the method called, or fails
/// with [failure]. `Future<Never>.error` is what lets one fake stand in for
/// every return type the use cases ask for.
class _FakeStudentRepository implements StudentRepository {
  _FakeStudentRepository({this.failure});

  final Object? failure;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final error = failure;
    if (error != null) return Future<Never>.error(error);
    return switch (invocation.memberName) {
      #generateGuardianPin || #changeGuardianPin => Future.value((
        message: 'PIN saved',
        newClockPin: _pin,
      )),
      #createGuardianUser => Future.value((
        message: 'Created',
        guardianCode: 'GRD-NEW',
      )),
      _ => Future.value('Saved'),
    };
  }
}

class _FakeStudentClassroomRepository implements StudentClassroomRepository {
  _FakeStudentClassroomRepository({this.failure});

  final Object? failure;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final error = failure;
    if (error != null) return Future<Never>.error(error);
    return Future.value('Assigned');
  }
}

class _FakeUserProfileRepository implements UserProfileRepository {
  _FakeUserProfileRepository({this.failure});

  final Object? failure;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final error = failure;
    if (error != null) return Future<Never>.error(error);
    return Future.value('Profile saved');
  }
}

const _pin = '4821';

/// Everything a log line must never carry: codes, names, contact details and
/// the PIN, as passed to the use cases below.
const _personalData = [
  'STU-1',
  'SCH-1',
  'ORG-1',
  'USR-1',
  'GRD-1',
  'GRD-NEW',
  'PHY-1',
  'DOC-1',
  'CLS-1',
  'TAG-1',
  'Jane',
  'Doe',
  'jane@example.com',
  '5551234567',
  _pin,
];

DioException _dio(int status) {
  final options = RequestOptions(path: '/students');
  return DioException(
    requestOptions: options,
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(requestOptions: options, statusCode: status),
  );
}

DioException _connectionError() => DioException(
  requestOptions: RequestOptions(path: '/students'),
  type: DioExceptionType.connectionError,
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

  Future<void> flush() =>
      Future<void>.delayed(const Duration(milliseconds: 50));

  Object? attribute(SentryLog log, String key) => log.attributes[key]?.value;

  void expectNoPersonalData() {
    for (final log in logs) {
      final values = [
        log.body,
        ...log.attributes.values.map((a) => '${a.value}'),
      ];
      for (final value in values) {
        for (final secret in _personalData) {
          expect(value, isNot(contains(secret)), reason: 'log leaked $secret');
        }
      }
    }
  }

  group('student writes', () {
    test(
      'each one logs a single succeeded line and returns untouched',
      () async {
        final repo = _FakeStudentRepository();

        final tags = await UpdateStudentTagsUseCase(repo)(
          studentCode: 'STU-1',
          schoolCode: 'SCH-1',
          tagCodes: const ['TAG-1'],
        );
        final pickup = await AddPickupUseCase(repo)(
          studentCode: 'STU-1',
          firstName: 'Jane',
          lastName: 'Doe',
          email: 'jane@example.com',
          phoneNumber: '5551234567',
          relation: 'Aunt',
          pickupType: 'REGULAR',
        );
        final physician = await DeletePhysicianUseCase(repo)(
          code: 'PHY-1',
          studentCode: 'STU-1',
        );
        await flush();

        expect([tags, pickup, physician], everyElement('Saved'));
        expect(logs.map((log) => log.body), [
          'student.tags_update.succeeded',
          'student.pickup_add.succeeded',
          'student.physician_delete.succeeded',
        ]);
        expect(
          logs.map((log) => attribute(log, 'outcome')),
          everyElement('succeeded'),
        );
        expectNoPersonalData();
      },
    );

    test(
      'a count is logged where the params carry one, and only there',
      () async {
        final repo = _FakeStudentRepository();

        await UpdateStudentTagsUseCase(repo)(
          studentCode: 'STU-1',
          schoolCode: 'SCH-1',
          tagCodes: const ['TAG-1', 'TAG-2', 'TAG-3'],
        );
        await AddStudentSiblingUseCase(repo)(
          studentCode: 'STU-1',
          siblingCodes: const ['STU-2', 'STU-3'],
        );
        await UpdateStudentSiblingsUseCase(repo)(
          studentCode: 'STU-1',
          siblingCodes: const [],
        );
        await UpdateStudentRegularSchedulesUseCase(repo)(
          schoolCode: 'SCH-1',
          studentCode: 'STU-1',
          schedule: const [
            StudentRegularScheduleInput(
              dayOfWeek: 'MONDAY',
              startTime: '08:00:00',
              halfDay: '12:00:00',
              endTime: '17:00:00',
            ),
            StudentRegularScheduleInput(
              dayOfWeek: 'TUESDAY',
              startTime: '08:00:00',
              halfDay: '12:00:00',
              endTime: '17:00:00',
            ),
          ],
        );
        await DeleteGuardianUseCase(repo)(code: 'GRD-1', studentCode: 'STU-1');
        await flush();

        expect(logs.map((log) => log.body), [
          'student.tags_update.succeeded',
          'student.sibling_add.succeeded',
          'student.siblings_update.succeeded',
          'student.schedules_update.succeeded',
          'guardian.delete.succeeded',
        ]);
        expect(logs.map((log) => attribute(log, 'count')), [3, 2, 0, 2, null]);
        expectNoPersonalData();
      },
    );

    test('a thrown error is bucketed, logged failed and rethrown', () async {
      await expectLater(
        UpdateStudentTagsUseCase(_FakeStudentRepository(failure: _dio(409)))(
          studentCode: 'STU-1',
          schoolCode: 'SCH-1',
          tagCodes: const ['TAG-1'],
        ),
        throwsA(isA<DioException>()),
      );
      await expectLater(
        DeletePhysicianUseCase(
          _FakeStudentRepository(failure: _connectionError()),
        )(code: 'PHY-1', studentCode: 'STU-1'),
        throwsA(isA<DioException>()),
      );
      await flush();

      expect(logs.map((log) => log.body), [
        'student.tags_update.failed',
        'student.physician_delete.failed',
      ]);
      expect(logs.map((log) => attribute(log, 'failure')), [
        'validation',
        'network',
      ]);
      expect(logs.first.attributes['count']?.value, 1);
      expectNoPersonalData();
    });
  });

  group('student documents, which return an Either', () {
    test('a success is Right and logged succeeded', () async {
      final result = await DeleteStudentDocumentUseCase(
        _FakeStudentRepository(),
      )(documentUuid: 'DOC-1', studentCode: 'STU-1');
      await flush();

      expect(result, const Right<Failure, String>('Saved'));
      expect(logs.map((log) => log.body), [
        'student.document_delete.succeeded',
      ]);
      expectNoPersonalData();
    });

    test(
      'a failure is Left for the caller, and the raw error is bucketed',
      () async {
        final result =
            await AddStudentDocumentUseCase(
              _FakeStudentRepository(failure: _dio(404)),
            )(
              studentCode: 'STU-1',
              name: 'Jane Doe vaccination card',
              type: 'MEDICAL',
              expiryDate: '2027-01-01',
              storagePath: 'docs/STU-1/card.pdf',
              mimeType: 'application/pdf',
              size: 2048,
            );
        await flush();

        expect(result.isLeft(), isTrue);
        expect(logs.map((log) => log.body), ['student.document_add.failed']);
        expect(attribute(logs.single, 'failure'), 'notFound');
        expectNoPersonalData();
      },
    );
  });

  group('guardians', () {
    test(
      'create, link, update, invite and PIN writes log without any identifier',
      () async {
        final repo = _FakeStudentRepository();

        final created = await CreateGuardianUserUseCase(repo)(
          schoolCode: 'SCH-1',
          studentCode: 'STU-1',
          firstName: 'Jane',
          lastName: 'Doe',
          email: 'jane@example.com',
          mobile: '5551234567',
          relationToStudent: 'Mother',
          primaryContact: true,
          legalCustody: true,
          userCode: 'USR-1',
          organizationCode: 'ORG-1',
        );
        await LinkExistingGuardianUseCase(repo)(
          guardianCode: 'GRD-1',
          studentCode: 'STU-1',
        );
        await UpdateGuardianUseCase(repo)(
          code: 'GRD-1',
          studentCode: 'STU-1',
          request: const UpdateGuardianRequest(
            userCode: 'USR-1',
            schoolCode: 'SCH-1',
            studentCode: 'STU-1',
            firstName: 'Jane',
            lastName: 'Doe',
            email: 'jane@example.com',
            mobile: '5551234567',
            relationToStudent: 'Mother',
            primaryContact: true,
            legalCustody: false,
          ),
        );
        await ResendGuardianInviteUseCase(repo)(
          invitedEmail: 'jane@example.com',
          userCode: 'USR-1',
          organizationCode: 'ORG-1',
          schoolCode: 'SCH-1',
        );
        final generated = await GenerateGuardianPinUseCase(repo)(
          guardianCode: 'GRD-1',
          studentCode: 'STU-1',
        );
        final changed = await ChangeGuardianPinUseCase(repo)(
          guardianCode: 'GRD-1',
          pin: _pin,
          studentCode: 'STU-1',
        );
        await flush();

        expect(created.guardianCode, 'GRD-NEW');
        expect(generated.newClockPin, _pin);
        expect(changed.newClockPin, _pin);
        expect(logs.map((log) => log.body), [
          'guardian.create.succeeded',
          'guardian.link.succeeded',
          'guardian.update.succeeded',
          'guardian.invite_resend.succeeded',
          'guardian.pin_generate.succeeded',
          'guardian.pin_change.succeeded',
        ]);
        expectNoPersonalData();
      },
    );

    test(
      'a failed PIN change is bucketed and the PIN stays out of the log',
      () async {
        await expectLater(
          ChangeGuardianPinUseCase(_FakeStudentRepository(failure: _dio(403)))(
            guardianCode: 'GRD-1',
            pin: _pin,
            studentCode: 'STU-1',
          ),
          throwsA(isA<DioException>()),
        );
        await flush();

        expect(logs.map((log) => log.body), ['guardian.pin_change.failed']);
        expect(attribute(logs.single, 'failure'), 'forbidden');
        expectNoPersonalData();
      },
    );
  });

  group('classroom assignment', () {
    test('logs the number of students moved', () async {
      final message =
          await AssignStudentsToClassroomUseCase(
            _FakeStudentClassroomRepository(),
          )(
            schoolCode: 'SCH-1',
            classroomCode: 'CLS-1',
            studentCodes: const ['STU-1', 'STU-2', 'STU-3', 'STU-4'],
          );
      await flush();

      expect(message, 'Assigned');
      expect(logs.map((log) => log.body), [
        'student.classroom_assign.succeeded',
      ]);
      expect(attribute(logs.single, 'count'), 4);
      expectNoPersonalData();
    });

    test(
      'keeps the count on a failure and still throws the friendly message',
      () async {
        await expectLater(
          AssignStudentsToClassroomUseCase(
            _FakeStudentClassroomRepository(failure: _dio(500)),
          )(
            schoolCode: 'SCH-1',
            classroomCode: 'CLS-1',
            studentCodes: const ['STU-1', 'STU-2'],
          ),
          throwsA(isA<String>()),
        );
        await flush();

        expect(logs.map((log) => log.body), [
          'student.classroom_assign.failed',
        ]);
        expect(attribute(logs.single, 'failure'), 'server');
        expect(attribute(logs.single, 'count'), 2);
        expectNoPersonalData();
      },
    );
  });

  group('guardian profile', () {
    const update = GuardianProfileUpdate(
      guardianCode: 'GRD-1',
      firstName: 'Jane',
      lastName: 'Doe',
      phoneDigits: '5551234567',
    );

    test('logs succeeded and returns the server message', () async {
      final message = await UpdateGuardianProfileUseCase(
        _FakeUserProfileRepository(),
      )(update);
      await flush();

      expect(message, 'Profile saved');
      expect(logs.map((log) => log.body), [
        'guardian.profile_update.succeeded',
      ]);
      expectNoPersonalData();
    });

    test('logs a failure bucket and rethrows', () async {
      await expectLater(
        UpdateGuardianProfileUseCase(
          _FakeUserProfileRepository(failure: _dio(422)),
        )(update),
        throwsA(isA<DioException>()),
      );
      await flush();

      expect(logs.map((log) => log.body), ['guardian.profile_update.failed']);
      expect(attribute(logs.single, 'failure'), 'validation');
      expectNoPersonalData();
    });
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
