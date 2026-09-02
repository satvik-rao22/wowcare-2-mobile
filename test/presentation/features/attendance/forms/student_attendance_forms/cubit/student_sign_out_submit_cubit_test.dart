import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/student_sign_out_request.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_student_sign_out_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_sign_out_submit_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/student_attendance_forms/cubit/student_sign_out_submit_state.dart';

class _UnusedStorageService implements StorageService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

const _request = StudentSignOutRequest(
  mode: StudentSignOutMode.staff,
  studentCodes: ['STU-1'],
  signOutMethod: 'APP',
  latitude: 0,
  longitude: 0,
  withinGeofence: false,
  timeZone: 'Asia/Kolkata',
);

class _UnusedRepo implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeSubmitUseCase extends SubmitStudentSignOutUseCase {
  _FakeSubmitUseCase() : super(_UnusedRepo());

  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;
  int calls = 0;
  bool? lastIsParent;

  @override
  Future<AttendanceActionResult> call({
    required StudentSignOutRequest request,
    required bool isParent,
    String? idempotencyKey,
  }) async {
    calls++;
    lastIsParent = isParent;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }
}

void main() {
  group('StudentSignOutSubmitCubit', () {
    late _FakeSubmitUseCase useCase;
    late StudentSignOutSubmitCubit cubit;

    setUp(() {
      useCase = _FakeSubmitUseCase();
      cubit = StudentSignOutSubmitCubit(
        useCase,
        storageService: _UnusedStorageService(),
        apiClient: ApiClient(baseUrl: 'http://unused'),
      );
    });

    tearDown(() => cubit.close());

    test('initial state is Initial and isSubmitting is false', () {
      expect(cubit.state, isA<StudentSignOutSubmitInitial>());
      expect(cubit.isSubmitting, isFalse);
    });

    test(
      'on success: emits InProgress then Success and returns the result',
      () async {
        const result = AttendanceActionResult(
          success: true,
          message: 'Signed-Out successfully',
        );
        useCase.resultToReturn = result;

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            isA<StudentSignOutSubmitInProgress>(),
            isA<StudentSignOutSubmitSuccess>(),
          ]),
        );

        final returned = await cubit.submit(request: _request, isParent: false);

        await expectation;
        expect(returned, same(result));
        expect(useCase.calls, 1);
        expect(useCase.lastIsParent, isFalse);
        expect(
          (cubit.state as StudentSignOutSubmitSuccess).result,
          same(result),
        );
      },
    );

    test(
      'a success:false response is still a (non-throwing) Success state',
      () async {
        const result = AttendanceActionResult(
          success: false,
          message: 'Already signed out',
        );
        useCase.resultToReturn = result;

        final returned = await cubit.submit(request: _request, isParent: true);

        expect(returned.success, isFalse);
        expect(cubit.state, isA<StudentSignOutSubmitSuccess>());
        expect(useCase.lastIsParent, isTrue);
      },
    );

    test('on error: emits InProgress then Failure and rethrows', () async {
      final error = Exception('boom');
      useCase.errorToThrow = error;

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<StudentSignOutSubmitInProgress>(),
          isA<StudentSignOutSubmitFailure>(),
        ]),
      );

      await expectLater(
        () => cubit.submit(request: _request, isParent: false),
        throwsA(same(error)),
      );

      await expectation;
      expect(cubit.state, isA<StudentSignOutSubmitFailure>());
    });
  });
}
