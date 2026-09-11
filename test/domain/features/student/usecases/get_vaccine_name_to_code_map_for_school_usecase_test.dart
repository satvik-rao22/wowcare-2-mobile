import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_vaccine_name_to_code_map_for_school_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<Map<String, String>> getVaccineNameToCodeMapForSchool({
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
  const entity = <String, String>{'Hepatitis B': 'VCC_HEPB'};

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = GetVaccineNameToCodeMapForSchoolUseCase(repo);
    final r = await useCase(schoolCode: 'SCH1');
    expect(r, same(entity));
    expect(repo.calls.single['schoolCode'], 'SCH1');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = GetVaccineNameToCodeMapForSchoolUseCase(repo);
    expect(() => useCase(schoolCode: 'SCH1'), throwsA(isA<Exception>()));
  });
}
