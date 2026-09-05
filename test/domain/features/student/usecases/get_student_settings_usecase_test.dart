import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_settings.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_settings_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<StudentSettings> getStudentSettings({required String schoolCode}) async {
    calls.add({'schoolCode': schoolCode});
    if (errorToThrow != null) throw errorToThrow!;
    return result as StudentSettings;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = StudentSettings(schoolCode: 'SCH1');

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = GetStudentSettingsUseCase(repo);
    final r = await useCase(schoolCode: 'SCH1');
    expect(r, same(entity));
    expect(repo.calls.single['schoolCode'], 'SCH1');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = GetStudentSettingsUseCase(repo);
    expect(() => useCase(schoolCode: 'SCH1'), throwsA(isA<Exception>()));
  });
}
