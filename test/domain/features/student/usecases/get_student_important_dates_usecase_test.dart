import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_important_dates.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_important_dates_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<StudentImportantDates> getStudentImportantDates({
    required String studentCode,
  }) async {
    calls.add({'studentCode': studentCode});
    if (errorToThrow != null) throw errorToThrow!;
    return result as StudentImportantDates;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = StudentImportantDates();

  test('returns the repository result as Right on success', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = GetStudentImportantDatesUseCase(repo);
    final r = await useCase(studentCode: 'S1');
    expect(r.isRight(), isTrue);
    expect(r.getOrElse(() => const StudentImportantDates()), same(entity));
    expect(repo.calls.single['studentCode'], 'S1');
  });

  test('returns a Left when the repository fails', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = GetStudentImportantDatesUseCase(repo);
    final r = await useCase(studentCode: 'S1');
    expect(r.isLeft(), isTrue);
  });
}
