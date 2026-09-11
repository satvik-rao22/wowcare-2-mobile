import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_guardian_name_code_map_for_school_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<Map<String, String>> getGuardianNameCodeMapForSchool({
    required String schoolCode,
  }) async {
    calls.add({'schoolCode': schoolCode});
    if (errorToThrow != null) throw errorToThrow!;
    return result as Map<String, String>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = {'Jane Doe': 'G1'};

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = GetGuardianNameCodeMapForSchoolUseCase(repo);
    final r = await useCase(schoolCode: 'SCH1');
    expect(r, same(entity));
    expect(repo.calls.single['schoolCode'], 'SCH1');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = GetGuardianNameCodeMapForSchoolUseCase(repo);
    expect(() => useCase(schoolCode: 'SCH1'), throwsA(isA<Exception>()));
  });
}
