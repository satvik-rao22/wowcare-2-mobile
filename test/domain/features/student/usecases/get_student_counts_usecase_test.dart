import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_counts_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<({int activeCount, int upcomingCount, int enrolledCount})>
  getStudentCounts({required String schoolCode}) async {
    calls.add({'schoolCode': schoolCode});
    if (errorToThrow != null) throw errorToThrow!;
    return result as ({int activeCount, int upcomingCount, int enrolledCount});
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = (activeCount: 3, upcomingCount: 1, enrolledCount: 4);

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = GetStudentCountsUseCase(repo);
    final r = await useCase(schoolCode: 'SCH1');
    expect(r, entity);
    expect(repo.calls.single['schoolCode'], 'SCH1');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = GetStudentCountsUseCase(repo);
    expect(() => useCase(schoolCode: 'SCH1'), throwsA(isA<Exception>()));
  });
}
