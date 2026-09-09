import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_profile.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_profile_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<StudentProfile> getStudentProfile({required String code}) async {
    calls.add({'code': code});
    if (errorToThrow != null) throw errorToThrow!;
    return result as StudentProfile;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = StudentProfile(
    code: 'S1',
    schoolCode: 'SCH1',
    fullName: 'Jane Doe',
  );

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = GetStudentProfileUseCase(repo);
    final r = await useCase(code: 'S1');
    expect(r, same(entity));
    expect(repo.calls.single['code'], 'S1');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = GetStudentProfileUseCase(repo);
    expect(() => useCase(code: 'S1'), throwsA(isA<Exception>()));
  });
}
