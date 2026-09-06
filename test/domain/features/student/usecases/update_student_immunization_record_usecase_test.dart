import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_immunization.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_immunization_record_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<StudentImmunization> updateStudentImmunizationRecord({
    required String studentCode,
    required StudentImmunization record,
    required DateTime date,
    required String status,
    String? exemptionReason,
  }) async {
    calls.add({
      'studentCode': studentCode,
      'record': record,
      'date': date,
      'status': status,
      'exemptionReason': exemptionReason,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as StudentImmunization;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const record = StudentImmunization(
    code: 'IMM1',
    studentCode: 'S1',
    vaccineName: 'MMR',
    vaccineDoseCode: 'VDC1',
    doseNumber: 1,
    status: 'DUE',
  );
  final date = DateTime(2026, 1, 1);

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = record;
    final useCase = UpdateStudentImmunizationRecordUseCase(repo);
    final r = await useCase(
      studentCode: 'S1',
      record: record,
      date: date,
      status: 'ADMINISTERED',
    );
    expect(r, same(record));
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['record'], same(record));
    expect(repo.calls.single['date'], date);
    expect(repo.calls.single['status'], 'ADMINISTERED');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdateStudentImmunizationRecordUseCase(repo);
    expect(
      () => useCase(
        studentCode: 'S1',
        record: record,
        date: date,
        status: 'ADMINISTERED',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
