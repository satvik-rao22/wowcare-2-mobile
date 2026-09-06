import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_physician.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_physician_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<StudentPhysician> updatePhysician({
    required String code,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String address,
    String? specialty,
    String? notes,
  }) async {
    calls.add({
      'code': code,
      'studentCode': studentCode,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'address': address,
      'specialty': specialty,
      'notes': notes,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as StudentPhysician;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = StudentPhysician(
    code: 'PHY1',
    firstName: 'Dr',
    lastName: 'Who',
    email: 'dr@example.com',
    phoneNumber: '555',
    address: '1 St',
    specialty: 'GP',
    notes: '',
    status: 'ACTIVE',
  );

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = UpdatePhysicianUseCase(repo);
    final r = await useCase(
      code: 'PHY1',
      studentCode: 'S1',
      firstName: 'Dr',
      lastName: 'Who',
      email: 'dr@example.com',
      phoneNumber: '555',
      address: '1 St',
      specialty: 'GP',
      notes: 'n',
    );
    expect(r, same(entity));
    expect(repo.calls.single['code'], 'PHY1');
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['email'], 'dr@example.com');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdatePhysicianUseCase(repo);
    expect(
      () => useCase(
        code: 'PHY1',
        studentCode: 'S1',
        firstName: 'Dr',
        lastName: 'Who',
        email: 'dr@example.com',
        phoneNumber: '555',
        address: '1 St',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
