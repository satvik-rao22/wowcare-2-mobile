import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_sign_in_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_in_submit_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_sign_in_submit_state.dart';

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
    required Map<String, dynamic> payload,
    required bool isSelf,
  }) async {
    calls++;
    lastIsSelf = isSelf;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }
}

void main() {
  group('StaffSignInSubmitCubit', () {
    late _FakeSubmitUseCase useCase;
    late StaffSignInSubmitCubit cubit;

    setUp(() {
      useCase = _FakeSubmitUseCase();
      cubit = StaffSignInSubmitCubit(useCase);
    });

    tearDown(() => cubit.close());

    test('initial state is Initial and isSubmitting is false', () {
      expect(cubit.state, isA<StaffSignInSubmitInitial>());
      expect(cubit.isSubmitting, isFalse);
    });

    test('on success: emits InProgress then Success and returns the result', () async {
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
        payload: const <String, dynamic>{'a': 1},
        isSelf: true,
      );

      await expectation;
      expect(returned, same(result));
      expect(useCase.calls, 1);
      expect(useCase.lastIsSelf, isTrue);
      expect(
        (cubit.state as StaffSignInSubmitSuccess).result,
        same(result),
      );
    });

    test('a success:false response is still a (non-throwing) Success state', () async {
      const result = AttendanceActionResult(
        success: false,
        message: 'Already signed in',
      );
      useCase.resultToReturn = result;

      final returned = await cubit.submit(
        payload: const <String, dynamic>{},
        isSelf: false,
      );

      expect(returned.success, isFalse);
      expect(cubit.state, isA<StaffSignInSubmitSuccess>());
      expect(useCase.lastIsSelf, isFalse);
    });

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
        () => cubit.submit(payload: const <String, dynamic>{}, isSelf: true),
        throwsA(same(error)),
      );

      await expectation;
      expect(cubit.state, isA<StaffSignInSubmitFailure>());
    });
  });
}
