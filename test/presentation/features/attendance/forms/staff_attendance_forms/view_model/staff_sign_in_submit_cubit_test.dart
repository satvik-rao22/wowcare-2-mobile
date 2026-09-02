import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_absent.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_sign_in_request.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_staff_absence_record_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_absent_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_sign_in_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_sign_in_submit_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/view_model/staff_sign_in_submit_state.dart';

const _sampleRequest = StaffSignInRequest(
  mode: StaffSignInMode.self,
  staffCode: 'STF-1',
  signInMethod: 'GPS',
  latitude: 0,
  longitude: 0,
  withinGeofence: true,
  timeZone: 'Asia/Kolkata',
  occurredAtIso: '2026-08-27T09:00:00.000Z',
  isExpectedToday: true,
);

/// The use case's constructor needs a repository, but the fake overrides
/// [call] so the repository is never touched.
class _UnusedRepo implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeSubmitUseCase extends SubmitStaffSignInUseCase {
  _FakeSubmitUseCase() : super(_UnusedRepo());

  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;
  int calls = 0;
  bool? lastIsSelf;

  @override
  Future<AttendanceActionResult> call({
    required StaffSignInRequest request,
    required bool isSelf,
    String? idempotencyKey,
  }) async {
    calls++;
    lastIsSelf = isSelf;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }
}

/// Fake absent-form-list lookup — returns an empty page by default so the
/// pre-delete step (not exercised by these submit()-focused tests) is a
/// no-op.
class _FakeGetStaffAbsentFormListUseCase extends GetStaffAbsentFormListUseCase {
  _FakeGetStaffAbsentFormListUseCase() : super(_UnusedRepo());

  @override
  Future<StaffAttendanceAbsentPage> call({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async {
    return const StaffAttendanceAbsentPage(
      items: [],
      page: 0,
      size: 0,
      totalPages: 0,
      totalElements: 0,
      hasMore: false,
    );
  }
}

class _FakeDeleteStaffAbsenceRecordUseCase
    extends DeleteStaffAbsenceRecordUseCase {
  _FakeDeleteStaffAbsenceRecordUseCase() : super(_UnusedRepo());

  @override
  Future<void> call({
    required String absenceRecordCode,
    required String staffCode,
  }) async {}
}

void main() {
  group('StaffSignInSubmitCubit', () {
    late _FakeSubmitUseCase useCase;
    late StaffSignInSubmitCubit cubit;

    setUp(() {
      useCase = _FakeSubmitUseCase();
      cubit = StaffSignInSubmitCubit(
        useCase,
        getStaffAbsentFormListUseCase: _FakeGetStaffAbsentFormListUseCase(),
        deleteStaffAbsenceRecordUseCase: _FakeDeleteStaffAbsenceRecordUseCase(),
      );
    });

    tearDown(() => cubit.close());

    test('initial state is Initial and isSubmitting is false', () {
      expect(cubit.state, isA<StaffSignInSubmitInitial>());
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
            isA<StaffSignInSubmitInProgress>(),
            isA<StaffSignInSubmitSuccess>(),
          ]),
        );

        final returned = await cubit.submit(
          request: _sampleRequest,
          isSelf: true,
        );

        await expectation;
        expect(returned, same(result));
        expect(useCase.calls, 1);
        expect(useCase.lastIsSelf, isTrue);
        expect((cubit.state as StaffSignInSubmitSuccess).result, same(result));
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

        final returned = await cubit.submit(
          request: _sampleRequest,
          isSelf: false,
        );

        expect(returned.success, isFalse);
        expect(cubit.state, isA<StaffSignInSubmitSuccess>());
        expect(useCase.lastIsSelf, isFalse);
      },
    );

    test('on error: emits InProgress then Failure and rethrows', () async {
      final error = Exception('boom');
      useCase.errorToThrow = error;

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<StaffSignInSubmitInProgress>(),
          isA<StaffSignInSubmitFailure>(),
        ]),
      );

      await expectLater(
        () => cubit.submit(request: _sampleRequest, isSelf: true),
        throwsA(same(error)),
      );

      await expectation;
      expect(cubit.state, isA<StaffSignInSubmitFailure>());
    });
  });
}
