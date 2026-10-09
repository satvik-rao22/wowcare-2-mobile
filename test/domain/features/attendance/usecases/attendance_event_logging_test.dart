import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_in_request.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/mark_students_absent_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_student_sign_in_usecase.dart';

/// Answers every repository call generically, so the test does not have to
/// mirror the repository's long signatures.
class _FakeAttendanceRepository implements AttendanceRepository {
  AttendanceActionResult signInResult = const AttendanceActionResult(
    success: true,
    message: 'ok',
  );
  Object? markAbsentError;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return switch (invocation.memberName) {
      #submitStudentSignIn => Future.value(signInResult),
      #markStudentsAbsent =>
        markAbsentError == null
            ? Future.value('ok')
            : Future<String>.error(markAbsentError!),
      _ => throw UnimplementedError('${invocation.memberName}'),
    };
  }
}

void main() {
  final logs = <SentryLog>[];
  late _FakeAttendanceRepository repo;

  setUp(() async {
    logs.clear();
    repo = _FakeAttendanceRepository();
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

  const request = StudentSignInRequest(
    mode: StudentSignInMode.staff,
    studentCodes: ['STU-1', 'STU-2', 'STU-3'],
    signInMethod: 'APP',
    latitude: 0,
    longitude: 0,
    withinGeofence: true,
    timeZone: 'UTC',
  );

  test('a sign-in logs its outcome with the student count only', () async {
    await SubmitStudentSignInUseCase(repo)(request: request, isParent: false);
    await settle();

    final log = logs.single;
    expect(log.body, 'attendance.student_sign_in.succeeded');
    expect(log.attributes['count']!.value, 3);
    expect(
      log.attributes.values.map((a) => '${a.value}'),
      isNot(contains(startsWith('STU-'))),
    );
  });

  test('a sign-in the backend refuses is logged as failed', () async {
    repo.signInResult = const AttendanceActionResult(
      success: false,
      message: 'no',
    );

    await SubmitStudentSignInUseCase(repo)(request: request, isParent: false);
    await settle();

    expect(logs.single.body, 'attendance.student_sign_in.failed');
    expect(logs.single.attributes['failure']!.value, 'server');
  });

  test('a mark-absent failure keeps the original error bucket', () async {
    repo.markAbsentError = DioException.connectionError(
      requestOptions: RequestOptions(path: '/x'),
      reason: 'offline',
    );

    await expectLater(
      MarkStudentsAbsentUseCase(repo)(
        staffCode: 'STF-1',
        studentCodes: const ['STU-1', 'STU-2'],
        absenceFromDate: '2026-10-01',
        absenceToDate: '2026-10-02',
        absenceReason: 'sick',
        absenceNotes: const {},
        classroomCode: 'CLS-1',
        isExpectedTodayByStudentCode: const {},
      ),
      throwsA(isA<String>()),
    );
    await settle();

    final log = logs.single;
    expect(log.body, 'attendance.student_mark_absent.failed');
    expect(log.attributes['failure']!.value, 'network');
    expect(log.attributes['count']!.value, 2);
  });
}

/// Nothing a unit test produces may reach the network.
class _DiscardingTransport implements Transport {
  @override
  Future<SentryId?> send(SentryEnvelope envelope) async => SentryId.empty();
}
