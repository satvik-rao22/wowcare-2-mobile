import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/student_transfer_request.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_student_transfer_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_transfer_submit_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_transfer_submit_state.dart';

const _request = StudentTransferRequest(
  transferDate: '2026-08-27',
  staffCode: 'STF-1',
  studentCodes: ['STU-1'],
  toClassroomCode: 'CLS_1',
  toClassroomCodeByStudentCode: {'STU-1': 'CLS_1'},
  timeZone: 'Asia/Kolkata',
  transferredAt: '2026-08-27T09:00:00.000Z',
);

/// The use case's constructor needs a repository, but the fake overrides
/// [call] so the repository is never touched.
class _UnusedRepo implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeSubmitUseCase extends SubmitStudentTransferUseCase {
  _FakeSubmitUseCase() : super(_UnusedRepo());

  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;
  int calls = 0;

  @override
  Future<AttendanceActionResult> call({
    required StudentTransferRequest request,
    String? idempotencyKey,
  }) async {
    calls++;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }
}

void main() {
  group('StudentTransferSubmitCubit', () {
    late _FakeSubmitUseCase useCase;
    late StudentTransferSubmitCubit cubit;

    setUp(() {
      useCase = _FakeSubmitUseCase();
      cubit = StudentTransferSubmitCubit(useCase);
    });

    tearDown(() => cubit.close());

    test('initial state is Initial and isSubmitting is false', () {
      expect(cubit.state, isA<StudentTransferSubmitInitial>());
      expect(cubit.isSubmitting, isFalse);
    });

    test('on success: emits InProgress then Success and returns the result', () async {
      const result = AttendanceActionResult(
        success: true,
        message: 'Transferred successfully',
      );
      useCase.resultToReturn = result;

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<StudentTransferSubmitInProgress>(),
          isA<StudentTransferSubmitSuccess>(),
        ]),
      );

      final returned = await cubit.submit(request: _request);

      await expectation;
      expect(returned, same(result));
      expect(useCase.calls, 1);
      expect(
        (cubit.state as StudentTransferSubmitSuccess).result,
        same(result),
      );
    });

    test('a success:false response is still a (non-throwing) Success state', () async {
      const result = AttendanceActionResult(
        success: false,
        message: 'Already in that classroom',
      );
      useCase.resultToReturn = result;

      final returned = await cubit.submit(request: _request);

      expect(returned.success, isFalse);
      expect(cubit.state, isA<StudentTransferSubmitSuccess>());
    });

    test('on error: emits InProgress then Failure and rethrows', () async {
      final error = Exception('boom');
      useCase.errorToThrow = error;

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<StudentTransferSubmitInProgress>(),
          isA<StudentTransferSubmitFailure>(),
        ]),
      );

      await expectLater(
        () => cubit.submit(request: _request),
        throwsA(same(error)),
      );

      await expectation;
      expect(cubit.state, isA<StudentTransferSubmitFailure>());
    });
  });
}
