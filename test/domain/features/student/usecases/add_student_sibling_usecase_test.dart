import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/add_student_sibling_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> addStudentSibling({
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
  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = 'linked';
    final useCase = AddStudentSiblingUseCase(repo);
    final r = await useCase(
      studentCode: 'S1',
      siblingCodes: const ['S2', 'S3'],
    );
    expect(r, 'linked');
    final call = repo.calls.single;
    expect(call['studentCode'], 'S1');
    expect(call['siblingCodes'], const ['S2', 'S3']);
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = AddStudentSiblingUseCase(repo);
    expect(
      () => useCase(studentCode: 'S1', siblingCodes: const ['S2']),
      throwsA(isA<Exception>()),
    );
  });
}
