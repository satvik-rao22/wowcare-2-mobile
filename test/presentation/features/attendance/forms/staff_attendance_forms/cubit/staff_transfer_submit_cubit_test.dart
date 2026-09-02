import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/entities/attendance_action_result.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_attendance_daily.dart';
import 'package:wowcare/domain/features/attendance/entities/staff_transfer_request.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/get_staff_transfer_form_list_usecase.dart';
import 'package:wowcare/domain/features/attendance/usecases/submit_staff_transfer_usecase.dart';
import 'package:wowcare/domain/features/staff/entities/staff_profile.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_staff_profile_usecase.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_transfer_submit_cubit.dart';
import 'package:wowcare/presentation/features/attendance/forms/staff_attendance_forms/cubit/staff_transfer_submit_state.dart';

const _request = StaffTransferRequest(
  staffCode: 'STF-1',
  staffCodes: ['STF-1'],
  toClassroomCode: 'CLS_1',
  toClassroomCodeByStaffCode: {'STF-1': 'CLS_1'},
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

class _FakeSubmitUseCase extends SubmitStaffTransferUseCase {
  _FakeSubmitUseCase() : super(_UnusedRepo());

  AttendanceActionResult? resultToReturn;
  Object? errorToThrow;
  int calls = 0;
  StaffTransferRequest? lastRequest;

  @override
  Future<AttendanceActionResult> call({
    required StaffTransferRequest request,
    String? idempotencyKey,
  }) async {
    calls++;
    lastRequest = request;
    if (errorToThrow != null) throw errorToThrow!;
    return resultToReturn!;
  }
}

/// The use case's constructor needs a repository, but the fake overrides
/// [call] so the repository is never touched.
class _UnusedAttendanceRepoForFormList implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGetStaffTransferFormListUseCase
    extends GetStaffTransferFormListUseCase {
  _FakeGetStaffTransferFormListUseCase()
    : super(_UnusedAttendanceRepoForFormList());

  @override
  Future<StaffAttendanceDailyPage> call({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) async => const StaffAttendanceDailyPage(
    items: [],
    page: 0,
    size: 10,
    totalPages: 0,
    totalElements: 0,
    hasMore: false,
  );
}

class _UnusedStaffRepo implements StaffRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeGetStaffProfileUseCase extends GetStaffProfileUseCase {
  _FakeGetStaffProfileUseCase() : super(_UnusedStaffRepo());

  @override
  Future<StaffProfile> call({
    required String staffCode,
    bool forEditStaff = true,
    bool forceRefresh = false,
  }) async => throw UnimplementedError('not stubbed for this test');
}

void main() {
  group('StaffTransferSubmitCubit', () {
    late _FakeSubmitUseCase useCase;
    late StaffTransferSubmitCubit cubit;

    setUp(() {
      useCase = _FakeSubmitUseCase();
      cubit = StaffTransferSubmitCubit(
        useCase,
        getStaffTransferFormListUseCase: _FakeGetStaffTransferFormListUseCase(),
        getStaffProfileUseCase: _FakeGetStaffProfileUseCase(),
      );
    });

    tearDown(() => cubit.close());

    test('initial state is Initial and isSubmitting is false', () {
      expect(cubit.state, isA<StaffTransferSubmitInitial>());
      expect(cubit.isSubmitting, isFalse);
    });

    test(
      'on success: emits InProgress then Success and returns the result',
      () async {
        const result = AttendanceActionResult(
          success: true,
          message: 'Transferred successfully',
        );
        useCase.resultToReturn = result;

        final expectation = expectLater(
          cubit.stream,
          emitsInOrder([
            isA<StaffTransferSubmitInProgress>(),
            isA<StaffTransferSubmitSuccess>(),
          ]),
        );

        final returned = await cubit.submit(request: _request);

        await expectation;
        expect(returned, same(result));
        expect(useCase.calls, 1);
        expect(useCase.lastRequest, same(_request));
        expect(
          (cubit.state as StaffTransferSubmitSuccess).result,
          same(result),
        );
      },
    );

    test(
      'a success:false response is still a (non-throwing) Success state',
      () async {
        const result = AttendanceActionResult(
          success: false,
          message: 'Already in that classroom',
        );
        useCase.resultToReturn = result;

        final returned = await cubit.submit(request: _request);

        expect(returned.success, isFalse);
        expect(cubit.state, isA<StaffTransferSubmitSuccess>());
      },
    );

    test('on error: emits InProgress then Failure and rethrows', () async {
      final error = Exception('boom');
      useCase.errorToThrow = error;

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<StaffTransferSubmitInProgress>(),
          isA<StaffTransferSubmitFailure>(),
        ]),
      );

      await expectLater(
        () => cubit.submit(request: _request),
        throwsA(same(error)),
      );

      await expectation;
      expect(cubit.state, isA<StaffTransferSubmitFailure>());
    });
  });
}
