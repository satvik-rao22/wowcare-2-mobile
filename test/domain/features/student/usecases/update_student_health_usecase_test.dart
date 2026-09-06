import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_health.dart';
import 'package:wowcare/domain/features/student/entities/student_health_update_request.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_health_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<StudentHealth> updateStudentHealth({
    required String studentCode,
    required StudentHealthUpdateRequest request,
  }) async {
    calls.add({'studentCode': studentCode, 'request': request});
    if (errorToThrow != null) throw errorToThrow!;
    return result as StudentHealth;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const request = StudentHealthUpdateRequest(
    allergy: 'none',
    medications: 'none',
    dietRestrictions: 'none',
    photoPermission: true,
  );
  const entity = StudentHealth(allergy: 'none');

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = UpdateStudentHealthUseCase(repo);
    final r = await useCase(studentCode: 'S1', request: request);
    expect(r, same(entity));
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['request'], same(request));
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdateStudentHealthUseCase(repo);
    expect(
      () => useCase(studentCode: 'S1', request: request),
      throwsA(isA<Exception>()),
    );
  });
}
