import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_physical_exam.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_physical_exam_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<StudentPhysicalExam> updateStudentPhysicalExam({
    required String studentCode,
    required String examCode,
    required DateTime examDate,
    required String status,
    String? notes,
  }) async {
    calls.add({
      'studentCode': studentCode,
      'examCode': examCode,
      'examDate': examDate,
      'status': status,
      'notes': notes,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as StudentPhysicalExam;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = StudentPhysicalExam(code: 'EX1');
  final examDate = DateTime(2026, 1, 1);

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = UpdateStudentPhysicalExamUseCase(repo);
    final r = await useCase(
      studentCode: 'S1',
      examCode: 'EX1',
      examDate: examDate,
      status: 'COMPLETED',
    );
    expect(r, same(entity));
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['examCode'], 'EX1');
    expect(repo.calls.single['examDate'], examDate);
    expect(repo.calls.single['status'], 'COMPLETED');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdateStudentPhysicalExamUseCase(repo);
    expect(
      () => useCase(
        studentCode: 'S1',
        examCode: 'EX1',
        examDate: examDate,
        status: 'COMPLETED',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
