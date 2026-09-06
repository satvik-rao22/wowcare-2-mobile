import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_siblings_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> updateStudentSiblings({
    required String studentCode,
    required List<String> siblingCodes,
  }) async {
    calls.add({'studentCode': studentCode, 'siblingCodes': siblingCodes});
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const siblingCodes = ['S2', 'S3'];

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = 'updated';
    final useCase = UpdateStudentSiblingsUseCase(repo);
    final r = await useCase(studentCode: 'S1', siblingCodes: siblingCodes);
    expect(r, 'updated');
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['siblingCodes'], same(siblingCodes));
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdateStudentSiblingsUseCase(repo);
    expect(
      () => useCase(studentCode: 'S1', siblingCodes: siblingCodes),
      throwsA(isA<Exception>()),
    );
  });
}
