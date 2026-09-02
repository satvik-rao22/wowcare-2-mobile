import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_sign_out_request.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_sign_out_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_out_submit_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_out_submit_state.dart';

const _sampleRequest = StaffSignOutRequest(
  attendanceDate: '2026-08-27',
  staffCode: 'STF-1',
  staffCodes: ['STF-1'],
  classroomCode: 'CLS_1',
  classroomCodeByStaffCode: {'STF-1': 'CLS_1'},
  signOutMethod: 'APP',
  latitude: 0,
  longitude: 0,
  withinGeofence: false,
  timeZone: 'Asia/Kolkata',
  occurredAtIso: '2026-08-27T09:00:00.000Z',
);

class _UnusedRepo implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeSubmitUseCase extends SubmitStaffSignOutUseCase {
  _FakeSubmitUseCase() : super(_UnusedRepo());

  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;
  int calls = 0;
  bool? lastIsSelf;

  @override
  Future<AttendanceActionResult> call({
    required StaffSignOutRequest request,
    bool isSelf = false,
    String? idempotencyKey,
  }) async {
    calls++;
    lastIsSelf = isSelf;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }
}

void main() {
  group('StaffSignOutSubmitCubit', () {
    late _FakeSubmitUseCase useCase;
    late StaffSignOutSubmitCubit cubit;

    setUp(() {
      useCase = _FakeSubmitUseCase();
      cubit = StaffSignOutSubmitCubit(useCase);
    });

    tearDown(() => cubit.close());

    test('initial state is Initial and isSubmitting is false', () {
      expect(cubit.state, isA<StaffSignOutSubmitInitial>());
      expect(cubit.isSubmitting, isFalse);
    });

    test('on success: emits InProgress then Success and returns the result', () async {
      const result = AttendanceActionResult(
        success: true,
        message: 'Signed-Out successfully',
      );
      useCase.resultToReturn = result;

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<StaffSignOutSubmitInProgress>(),
          isA<StaffSignOutSubmitSuccess>(),
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
      expect(
        (cubit.state as StaffSignOutSubmitSuccess).result,
        same(result),
      );
    });

    test('a success:false response is still a (non-throwing) Success state', () async {
      const result = AttendanceActionResult(
        success: false,
        message: 'Already signed out',
      );
      useCase.resultToReturn = result;

      final returned = await cubit.submit(
        request: _sampleRequest,
        isSelf: false,
      );

      expect(returned.success, isFalse);
      expect(cubit.state, isA<StaffSignOutSubmitSuccess>());
      expect(useCase.lastIsSelf, isFalse);
    });

    test('on error: emits InProgress then Failure and rethrows', () async {
      final error = Exception('boom');
      useCase.errorToThrow = error;

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<StaffSignOutSubmitInProgress>(),
          isA<StaffSignOutSubmitFailure>(),
        ]),
      );

      await expectLater(
        () => cubit.submit(request: _sampleRequest, isSelf: false),
        throwsA(same(error)),
      );

      await expectation;
      expect(cubit.state, isA<StaffSignOutSubmitFailure>());
    });
  });
}
