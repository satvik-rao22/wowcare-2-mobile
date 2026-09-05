import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/student/entities/student_important_dates.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_important_dates_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> updateStudentImportantDates({
    required String studentCode,
    required StudentImportantDates dates,
  }) async {
    calls.add({'studentCode': studentCode, 'dates': dates});
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  final dates = StudentImportantDates(enrollDate: DateTime(2026, 1, 1));

  test('forwards args and returns the repository Right on success', () async {
    final repo = _FakeRepo()..result = 'ok';
    final useCase = UpdateStudentImportantDatesUseCase(repo);
    final r = await useCase(studentCode: 'S1', dates: dates);
    expect(r.isRight(), isTrue);
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['dates'], same(dates));
  });

  test('returns a Left when the repository fails', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdateStudentImportantDatesUseCase(repo);
    final r = await useCase(studentCode: 'S1', dates: dates);
    expect(r.isLeft(), isTrue);
    r.fold((l) => expect(l, isA<ServerFailure>()), (_) => fail('expected Left'));
  });
}
