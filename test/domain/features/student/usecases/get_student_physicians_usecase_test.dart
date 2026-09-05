import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_physician.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_physicians_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<List<StudentPhysician>> getStudentPhysicians({
    required String studentCode,
  }) async {
    calls.add({'studentCode': studentCode});
    if (errorToThrow != null) throw errorToThrow!;
    return result as List<StudentPhysician>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  final entity = <StudentPhysician>[];

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = GetStudentPhysiciansUseCase(repo);
    final r = await useCase(studentCode: 'S1');
    expect(r, same(entity));
    expect(repo.calls.single['studentCode'], 'S1');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = GetStudentPhysiciansUseCase(repo);
    expect(() => useCase(studentCode: 'S1'), throwsA(isA<Exception>()));
  });
}
