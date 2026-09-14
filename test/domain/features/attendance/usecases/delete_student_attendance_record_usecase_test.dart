import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_student_attendance_record_usecase.dart';

class _FakeAttendanceRepository implements AttendanceRepository {
  String? capturedRecordCode;
  String? capturedStaffCode;
  Object? errorToThrow;
  int calls = 0;

  @override
  Future<void> deleteStudentAttendanceRecord({
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
  group('DeleteStudentAttendanceRecordUseCase', () {
    late _FakeAttendanceRepository repo;
    late DeleteStudentAttendanceRecordUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = DeleteStudentAttendanceRecordUseCase(repo);
    });

    test('forwards both codes to the repository and completes', () async {
      await useCase(attendanceRecordCode: 'ATT-2', staffCode: 'STF-7');

      expect(repo.calls, 1);
      expect(repo.capturedRecordCode, 'ATT-2');
      expect(repo.capturedStaffCode, 'STF-7');
    });

    test('propagates repository errors unchanged', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(attendanceRecordCode: 'ATT-2', staffCode: 'STF-7'),
        throwsA(same(failure)),
      );
    });
  });
}
