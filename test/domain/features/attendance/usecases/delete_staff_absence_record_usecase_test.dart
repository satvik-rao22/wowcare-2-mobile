import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/attendance/repositories/attendance_repository.dart';
import 'package:wowcare/domain/features/attendance/usecases/delete_staff_absence_record_usecase.dart';

class _FakeAttendanceRepository implements AttendanceRepository {
  String? capturedRecordCode;
  String? capturedStaffCode;
  Object? errorToThrow;
  int calls = 0;

  @override
  Future<void> deleteStaffAbsenceRecord({
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
  group('DeleteStaffAbsenceRecordUseCase', () {
    late _FakeAttendanceRepository repo;
    late DeleteStaffAbsenceRecordUseCase useCase;

    setUp(() {
      repo = _FakeAttendanceRepository();
      useCase = DeleteStaffAbsenceRecordUseCase(repo);
    });

    test('forwards both codes to the repository and completes', () async {
      await useCase(absenceRecordCode: 'ABS-3', staffCode: 'STF-2');

      expect(repo.calls, 1);
      expect(repo.capturedRecordCode, 'ABS-3');
      expect(repo.capturedStaffCode, 'STF-2');
    });

    test('propagates repository errors unchanged', () {
      final failure = Exception('network down');
      repo.errorToThrow = failure;

      expect(
        () => useCase(absenceRecordCode: 'ABS-3', staffCode: 'STF-2'),
        throwsA(same(failure)),
      );
    });
  });
}
