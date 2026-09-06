import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_tag_names_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<List<String>> getStudentTagNames({required String studentCode}) async {
    calls.add({'studentCode': studentCode});
    if (errorToThrow != null) throw errorToThrow!;
    return result as List<String>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = <String>['5 Days', 'Vegetarian'];

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = GetStudentTagNamesUseCase(repo);
    final r = await useCase(studentCode: 'S1');
    expect(r, same(entity));
    expect(repo.calls.single['studentCode'], 'S1');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = GetStudentTagNamesUseCase(repo);
    expect(() => useCase(studentCode: 'S1'), throwsA(isA<Exception>()));
  });
}
