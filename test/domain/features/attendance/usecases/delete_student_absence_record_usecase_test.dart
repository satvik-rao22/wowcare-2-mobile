import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_student_absence_record_usecase.dart';

class _FakeAttendanceRepository implements AttendanceRepository {
  String? capturedRecordCode;
  String? capturedStaffCode;
  Object? errorToThrow;
  int calls = 0;

  @override
  Future<void> deleteStudentAbsenceRecord({
    required String absenceRecordCode,
    required String staffCode,
  }) async {
    calls++;
    capturedRecordCode = absenceRecordCode;
    capturedStaffCode = staffCode;
    if (errorToThrow != null) throw errorToThrow!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  group('DeleteStudentAbsenceRecordUseCase', () {
    late _FakeAttendanceRepository repo;
    late DeleteStudentAbsenceRecordUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = DeleteStudentAbsenceRecordUseCase(repo);
    });

    test('forwards both codes to the repository and completes', () async {
      await useCase(absenceRecordCode: 'ABS-9', staffCode: 'STF-7');

      expect(repo.calls, 1);
      expect(repo.capturedRecordCode, 'ABS-9');
      expect(repo.capturedStaffCode, 'STF-7');
    });

    test('propagates repository errors unchanged', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(absenceRecordCode: 'ABS-9', staffCode: 'STF-7'),
        throwsA(same(failure)),
      );
    });
  });
}
