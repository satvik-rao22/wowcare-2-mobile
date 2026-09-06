import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/update_guardian_request.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_guardian_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> updateGuardian({
    required String code,
    required String studentCode,
    required UpdateGuardianRequest request,
  }) async {
    calls.add({
      'code': code,
      'studentCode': studentCode,
      'request': request,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const request = UpdateGuardianRequest(
    userCode: 'U1',
    schoolCode: 'SCH1',
    studentCode: 'S1',
    firstName: 'Ann',
    lastName: 'Lee',
    email: 'ann@example.com',
    mobile: '555',
    relationToStudent: 'Parent',
    primaryContact: true,
    legalCustody: true,
  );
  const entity = 'updated';

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = UpdateGuardianUseCase(repo);
    final r = await useCase(code: 'G1', studentCode: 'S1', request: request);
    expect(r, same(entity));
    expect(repo.calls.single['code'], 'G1');
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['request'], same(request));
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdateGuardianUseCase(repo);
    expect(
      () => useCase(code: 'G1', studentCode: 'S1', request: request),
      throwsA(isA<Exception>()),
    );
  });
}
