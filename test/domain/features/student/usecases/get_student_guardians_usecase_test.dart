import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_guardian.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_guardians_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<List<StudentGuardian>> getStudentGuardians({
    required String studentCode,
    bool forceRefresh = false,
  }) async {
    calls.add({'studentCode': studentCode, 'forceRefresh': forceRefresh});
    if (errorToThrow != null) throw errorToThrow!;
    return result as List<StudentGuardian>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  final entity = <StudentGuardian>[];

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = GetStudentGuardiansUseCase(repo);
    final r = await useCase(studentCode: 'S1', forceRefresh: true);
    expect(r, same(entity));
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['forceRefresh'], true);
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = GetStudentGuardiansUseCase(repo);
    expect(() => useCase(studentCode: 'S1'), throwsA(isA<Exception>()));
  });
}
