import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/create_student_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<Student> createStudent({
    required String schoolCode,
    required String firstName,
    required String lastName,
    required String status,
    required String classroom,
    String? profilePhotoUrl,
    DateTime? dob,
    DateTime? schoolStartDate,
  }) async {
    calls.add({
      'schoolCode': schoolCode,
      'firstName': firstName,
      'lastName': lastName,
      'status': status,
      'classroom': classroom,
      'profilePhotoUrl': profilePhotoUrl,
      'dob': dob,
      'schoolStartDate': schoolStartDate,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as Student;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = Student(
    code: 'S1',
    firstName: 'Alan',
    lastName: 'Turing',
    status: 'ACTIVE',
  );
  final dob = DateTime(2020, 5, 1);
  final startDate = DateTime(2026, 9, 1);

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = CreateStudentUseCase(repo);
    final r = await useCase(
      schoolCode: 'SCH1',
      firstName: 'Alan',
      lastName: 'Turing',
      status: 'ACTIVE',
      classroom: 'CLS_1',
      profilePhotoUrl: 'url',
      dob: dob,
      schoolStartDate: startDate,
    );
    expect(r, same(entity));
    final call = repo.calls.single;
    expect(call['schoolCode'], 'SCH1');
    expect(call['firstName'], 'Alan');
    expect(call['status'], 'ACTIVE');
    expect(call['classroom'], 'CLS_1');
    expect(call['dob'], dob);
    expect(call['schoolStartDate'], startDate);
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = CreateStudentUseCase(repo);
    expect(
      () => useCase(
        schoolCode: 'SCH1',
        firstName: 'Alan',
        lastName: 'Turing',
        status: 'ACTIVE',
        classroom: 'CLS_1',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
