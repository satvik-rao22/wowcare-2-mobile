import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_staff_attendance_record_usecase.dart';

class _FakeAttendanceRepository implements AttendanceRepository {
  String? capturedRecordCode;
  String? capturedStaffCode;
  Object? errorToThrow;
  int calls = 0;

  @override
  Future<void> deleteStaffAttendanceRecord({
    required String attendanceRecordCode,
    required String staffCode,
  }) async {
    calls++;
    capturedRecordCode = attendanceRecordCode;
    capturedStaffCode = staffCode;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  group('DeleteStaffAttendanceRecordUseCase', () {
    late _FakeAttendanceRepository repo;
    late DeleteStaffAttendanceRecordUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = DeleteStaffAttendanceRecordUseCase(repo);
    });

    test('forwards both codes to the repository and completes', () async {
      await useCase(attendanceRecordCode: 'ATT-1', staffCode: 'STF-9');

      expect(repo.calls, 1);
      expect(repo.capturedRecordCode, 'ATT-1');
      expect(repo.capturedStaffCode, 'STF-9');
    });

    test('propagates repository errors unchanged', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(attendanceRecordCode: 'ATT-1', staffCode: 'STF-9'),
        throwsA(same(failure)),
      );
    });
  });
}
