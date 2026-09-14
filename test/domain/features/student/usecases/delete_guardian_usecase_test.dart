import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/delete_guardian_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> deleteGuardian({
    required String code,
    required String studentCode,
  }) async {
    calls.add({'code': code, 'studentCode': studentCode});
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = 'deleted';
    final useCase = DeleteGuardianUseCase(repo);
    final r = await useCase(code: 'G1', studentCode: 'S1');
    expect(r, 'deleted');
    final call = repo.calls.single;
    expect(call['code'], 'G1');
    expect(call['studentCode'], 'S1');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = DeleteGuardianUseCase(repo);
    expect(
      () => useCase(code: 'G1', studentCode: 'S1'),
      throwsA(isA<Exception>()),
    );
  });
}
