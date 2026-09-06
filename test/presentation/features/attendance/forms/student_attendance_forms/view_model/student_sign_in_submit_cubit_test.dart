import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_absent_form.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_in_request.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_student_absence_record_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_student_absent_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_student_sign_in_usecase.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/view_model/student_sign_in_submit_cubit.dart';
import 'package:wowcare/presentation/features/attendance/view/student_attendance_forms/view_model/student_sign_in_submit_state.dart';

const _request = StudentSignInRequest(
  mode: StudentSignInMode.staff,
  studentCodes: ['STU-1'],
  signInMethod: 'APP',
  latitude: 0,
  longitude: 0,
  withinGeofence: true,
  timeZone: 'Asia/Kolkata',
);

/// The use case's constructor needs a repository, but the fake overrides
/// [call] so the repository is never touched.
class _UnusedRepo implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeSubmitUseCase extends SubmitStudentSignInUseCase {
  _FakeSubmitUseCase() : super(_UnusedRepo());

  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;
  int calls = 0;
  bool? lastIsParent;

  @override
  Future<AttendanceActionResult> call({
    required StudentSignInRequest request,
    required bool isParent,
    String? idempotencyKey,
  }) async {
    calls++;
    lastIsParent = isParent;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }
}

/// Fake absent-form-list lookup — returns an empty page by default so the
/// pre-delete step (not exercised by these submit()-focused tests) is a
/// no-op.
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
  group('StudentSignInSubmitCubit', () {
    late _FakeSubmitUseCase useCase;
    late StudentSignInSubmitCubit cubit;

    setUp(() {
      useCase = _FakeSubmitUseCase();
      cubit = StudentSignInSubmitCubit(
        useCase,
        getStudentAbsentFormListUseCase: _FakeGetStudentAbsentFormListUseCase(),
        deleteStudentAbsenceRecordUseCase:
            _FakeDeleteStudentAbsenceRecordUseCase(),
      );
    });

    tearDown(() => cubit.close());

    test('initial state is Initial and isSubmitting is false', () {
      expect(cubit.state, isA<StudentSignInSubmitInitial>());
      expect(cubit.isSubmitting, isFalse);
    });

    test(
      'on success: emits InProgress then Success and returns the result',
      () async {
        const result = AttendanceActionResult(
          success: true,
          message: 'Signed-In successfully',
        );
        useCase.resultToReturn = result;

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            isA<StudentSignInSubmitInProgress>(),
            isA<StudentSignInSubmitSuccess>(),
          ]),
        );

        final returned = await cubit.submit(request: _request, isParent: false);

        await expectation;
        expect(returned, same(result));
        expect(useCase.calls, 1);
        expect(useCase.lastIsParent, isFalse);
        expect(
          (cubit.state as StudentSignInSubmitSuccess).result,
          same(result),
        );
      },
    );

    test(
      'a success:false response is still a (non-throwing) Success state',
      () async {
        const result = AttendanceActionResult(
          success: false,
          message: 'Already signed in',
        );
        useCase.resultToReturn = result;

        final returned = await cubit.submit(request: _request, isParent: true);

        expect(returned.success, isFalse);
        expect(cubit.state, isA<StudentSignInSubmitSuccess>());
        expect(useCase.lastIsParent, isTrue);
      },
    );

    test('on error: emits InProgress then Failure and rethrows', () async {
      final error = Exception('boom');
      useCase.errorToThrow = error;

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<StudentSignInSubmitInProgress>(),
          isA<StudentSignInSubmitFailure>(),
        ]),
      );

      await expectLater(
        () => cubit.submit(request: _request, isParent: false),
        throwsA(same(error)),
      );

      await expectation;
      expect(cubit.state, isA<StudentSignInSubmitFailure>());
    });
  });
}
