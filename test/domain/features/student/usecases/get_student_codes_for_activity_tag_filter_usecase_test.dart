import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_codes_for_activity_tag_filter_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<List<String>> getStudentCodesForActivityTagFilter({
    required String schoolCode,
    required String classroomCode,
    required List<String> tagCodes,
  }) async {
    calls.add({
      'schoolCode': schoolCode,
      'classroomCode': classroomCode,
      'tagCodes': tagCodes,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as List<String>;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = ['S1', 'S2'];

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = GetStudentCodesForActivityTagFilterUseCase(repo);
    final r = await useCase(
      schoolCode: 'SCH1',
      classroomCode: 'C1',
      tagCodes: const ['T1'],
    );
    expect(r, same(entity));
    expect(repo.calls.single['schoolCode'], 'SCH1');
    expect(repo.calls.single['classroomCode'], 'C1');
    expect(repo.calls.single['tagCodes'], const ['T1']);
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = GetStudentCodesForActivityTagFilterUseCase(repo);
    expect(
      () => useCase(
        schoolCode: 'SCH1',
        classroomCode: 'C1',
        tagCodes: const ['T1'],
      ),
      throwsA(isA<Exception>()),
    );
  });
}
