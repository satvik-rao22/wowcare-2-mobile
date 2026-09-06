import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_tags_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> updateStudentTags({
    required String studentCode,
    required String schoolCode,
    required List<String> tagCodes,
  }) async {
    calls.add({
      'studentCode': studentCode,
      'schoolCode': schoolCode,
      'tagCodes': tagCodes,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const tagCodes = ['TAG_1', 'TAG_2'];

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = 'updated';
    final useCase = UpdateStudentTagsUseCase(repo);
    final r = await useCase(
      studentCode: 'S1',
      schoolCode: 'SCH1',
      tagCodes: tagCodes,
    );
    expect(r, 'updated');
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['schoolCode'], 'SCH1');
    expect(repo.calls.single['tagCodes'], same(tagCodes));
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdateStudentTagsUseCase(repo);
    expect(
      () => useCase(studentCode: 'S1', schoolCode: 'SCH1', tagCodes: tagCodes),
      throwsA(isA<Exception>()),
    );
  });
}
