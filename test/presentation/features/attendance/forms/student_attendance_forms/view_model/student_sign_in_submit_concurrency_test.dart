import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_in_request.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_student_absence_record_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_absent_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_student_sign_in_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/view_model/student_sign_in_submit_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/view_model/student_sign_in_submit_state.dart';

const _request = StudentSignInRequest(
  mode: StudentSignInMode.staff,
  studentCodes: ['STU-1'],
  signInMethod: 'APP',
  latitude: 0,
  longitude: 0,
  withinGeofence: true,
  timeZone: 'Asia/Kolkata',
);

const _ok = AttendanceActionResult(success: true, message: 'ok');

class _UnusedRepo implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

/// Use case whose [call] blocks on a caller-controlled [gate] so a submit can be
/// held "in flight", and which counts how many times it was invoked.
class _BlockingUseCase extends SubmitStudentSignInUseCase {
  _BlockingUseCase() : super(_UnusedRepo());

  int calls = 0;
  final Completer<AttendanceActionResult> gate =
      Completer<AttendanceActionResult>();

  @override
  Future<AttendanceActionResult> call({
    required StudentSignInRequest request,
    required bool isParent,
    String? idempotencyKey,
  }) {
    calls++;
    return gate.future;
  }
}

/// Fake absent-form-list lookup — returns an empty page by default so the
/// pre-delete step (not exercised by these concurrency tests) is a no-op.
class _FakeGetStudentAbsentFormListUseCase
    extends GetStudentAbsentFormListUseCase {
  _FakeGetStudentAbsentFormListUseCase() : super(_UnusedRepo());

  @override
  Future<StudentAttendanceAbsentFormPage> call({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    return const StudentAttendanceAbsentFormPage(
      items: [],
      page: 0,
      size: 0,
      totalPages: 0,
      totalElements: 0,
      hasMore: false,
    );
  }
}

class _FakeDeleteStudentAbsenceRecordUseCase
    extends DeleteStudentAbsenceRecordUseCase {
  _FakeDeleteStudentAbsenceRecordUseCase() : super(_UnusedRepo());

  @override
  Future<void> call({
    required String absenceRecordCode,
    required String staffCode,
  }) async {}
}

void main() {
  group('StudentSignInSubmitCubit — concurrency', () {
    late _BlockingUseCase useCase;
    late StudentSignInSubmitCubit cubit;

    setUp(() {
      useCase = _BlockingUseCase();
      cubit = StudentSignInSubmitCubit(
        useCase,
        getStudentAbsentFormListUseCase: _FakeGetStudentAbsentFormListUseCase(),
        deleteStudentAbsenceRecordUseCase:
            _FakeDeleteStudentAbsenceRecordUseCase(),
      );
    });

    tearDown(() => cubit.close());

    test(
      'while a submit is in flight, isSubmitting is true / state is InProgress; '
      'on completion it flips to Success',
      () async {
        expect(cubit.isSubmitting, isFalse);

        // Fire without awaiting — the use case blocks on the gate.
        final future = cubit.submit(request: _request, isParent: false);
        await Future<void>.delayed(
          Duration.zero,
        ); // let submit() reach the await

        expect(cubit.isSubmitting, isTrue);
        expect(cubit.state, isA<StudentSignInSubmitInProgress>());
        expect(useCase.calls, 1);

        useCase.gate.complete(_ok);
        final result = await future;

        expect(result.success, isTrue);
        expect(cubit.isSubmitting, isFalse);
        expect(cubit.state, isA<StudentSignInSubmitSuccess>());
      },
    );

    test(
      'the cubit does NOT itself serialise concurrent submit() calls — a second '
      'call while the first is in flight invokes the use case AGAIN. The '
      'duplicate-write guarantee is enforced elsewhere: the form\'s '
      '_submitInFlight re-entrancy guard (Task 03) and the backend '
      'Idempotency-Key (Task 09). This test documents the current cubit contract.',
      () async {
        final f1 = cubit.submit(request: _request, isParent: false);
        final f2 = cubit.submit(request: _request, isParent: false);
        await Future<void>.delayed(Duration.zero);

        // Both calls entered the use case — the cubit does not dedupe.
        expect(useCase.calls, 2);

        useCase.gate.complete(_ok);
        await Future.wait<AttendanceActionResult>([f1, f2]);

        expect(cubit.state, isA<StudentSignInSubmitSuccess>());
      },
    );
  });
}
