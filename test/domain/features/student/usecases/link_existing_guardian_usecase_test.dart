import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/link_existing_guardian_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> linkExistingGuardian({
    required String guardianCode,
    required String studentCode,
    String? relation,
    String? relationDescription,
  }) async {
    calls.add({
      'guardianCode': guardianCode,
      'studentCode': studentCode,
      'relation': relation,
      'relationDescription': relationDescription,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = 'linked';

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = LinkExistingGuardianUseCase(repo);
    final r = await useCase(
      guardianCode: 'G1',
      studentCode: 'S1',
      relation: 'Parent',
      relationDescription: 'desc',
    );
    expect(r, same(entity));
    expect(repo.calls.single['guardianCode'], 'G1');
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['relation'], 'Parent');
    expect(repo.calls.single['relationDescription'], 'desc');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = LinkExistingGuardianUseCase(repo);
    expect(
      () => useCase(guardianCode: 'G1', studentCode: 'S1'),
      throwsA(isA<Exception>()),
    );
  });
}
