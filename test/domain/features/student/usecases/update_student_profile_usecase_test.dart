import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/update_student_profile_request.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_profile_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> updateStudentProfile({
    required String code,
    required UpdateStudentProfileRequest request,
  }) async {
    calls.add({'code': code, 'request': request});
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const request = UpdateStudentProfileRequest(
    firstName: 'Ann',
    lastName: 'Lee',
    status: 'ACTIVE',
    classroomCode: 'C1',
    classroomName: 'Room 1',
  );

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = 'updated';
    final useCase = UpdateStudentProfileUseCase(repo);
    final r = await useCase(code: 'S1', request: request);
    expect(r, 'updated');
    expect(repo.calls.single['code'], 'S1');
    expect(repo.calls.single['request'], same(request));
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdateStudentProfileUseCase(repo);
    expect(
      () => useCase(code: 'S1', request: request),
      throwsA(isA<Exception>()),
    );
  });
}
