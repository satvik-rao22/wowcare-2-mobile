import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_physical_exam.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/add_student_physical_exam_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<StudentPhysicalExam> addStudentPhysicalExam({
    required String studentCode,
    required DateTime examDate,
    required String status,
    String? notes,
  }) async {
    calls.add({
      'studentCode': studentCode,
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
  const entity = StudentPhysicalExam(code: 'EX1', status: 'COMPLETED');
  final examDate = DateTime(2026, 1, 15);

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = AddStudentPhysicalExamUseCase(repo);
    final r = await useCase(
      studentCode: 'S1',
      examDate: examDate,
      status: 'COMPLETED',
      notes: 'n',
    );
    expect(r, same(entity));
    final call = repo.calls.single;
    expect(call['studentCode'], 'S1');
    expect(call['examDate'], examDate);
    expect(call['status'], 'COMPLETED');
    expect(call['notes'], 'n');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = AddStudentPhysicalExamUseCase(repo);
    expect(
      () => useCase(
        studentCode: 'S1',
        examDate: examDate,
        status: 'COMPLETED',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
