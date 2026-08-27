import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_staff_attendance_record_usecase.dart';
import 'package:wowcare/presentation/features/attendance/cubit/attendance_delete_state.dart';
import 'package:wowcare/presentation/features/attendance/cubit/staff_attendance_delete_cubit.dart';

class _UnusedRepo implements AttendanceRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _FakeDeleteUseCase extends DeleteStaffAttendanceRecordUseCase {
  _FakeDeleteUseCase() : super(_UnusedRepo());

  Object? errorToThrow;
  int calls = 0;
  String? lastRecordCode;
  String? lastStaffCode;

  @override
  Future<void> call({
    required String attendanceRecordCode,
    required String staffCode,
  }) async {
    calls++;
    lastRecordCode = attendanceRecordCode;
    lastStaffCode = staffCode;
    if (errorToThrow != null) throw errorToThrow!;
  }
}

void main() {
  group('StaffAttendanceDeleteCubit', () {
    late _FakeDeleteUseCase useCase;
    late StaffAttendanceDeleteCubit cubit;

    setUp(() {
      useCase = _FakeDeleteUseCase();
      cubit = StaffAttendanceDeleteCubit(useCase);
    });

    tearDown(() => cubit.close());

    test('initial state is Initial and isDeleting is false', () {
      expect(cubit.state, isA<AttendanceDeleteInitial>());
      expect(cubit.isDeleting, isFalse);
    });

    test('on success: forwards codes and emits InProgress then Success', () async {
      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AttendanceDeleteInProgress>(),
          isA<AttendanceDeleteSuccess>(),
        ]),
      );

      await cubit.delete(attendanceRecordCode: 'ATT-1', staffCode: 'STF-9');

      await expectation;
      expect(useCase.calls, 1);
      expect(useCase.lastRecordCode, 'ATT-1');
      expect(useCase.lastStaffCode, 'STF-9');
      expect(cubit.state, isA<AttendanceDeleteSuccess>());
    });

    test('on error: emits InProgress then Failure and rethrows', () async {
      final error = Exception('boom');
      useCase.errorToThrow = error;

      final expectation = expectLater(
        cubit.stream,
        emitsInOrder([
          isA<AttendanceDeleteInProgress>(),
          isA<AttendanceDeleteFailure>(),
        ]),
      );

      await expectLater(
        () => cubit.delete(attendanceRecordCode: 'ATT-1', staffCode: 'STF-9'),
        throwsA(same(error)),
      );

      await expectation;
      expect(cubit.state, isA<AttendanceDeleteFailure>());
    });
  });
}
