import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/add_pickup_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> addPickup({
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
    String? relationshipDescription,
    required String pickupType,
    String? carpoolId,
  }) async {
    calls.add({
      'studentCode': studentCode,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'relation': relation,
      'relationshipDescription': relationshipDescription,
      'pickupType': pickupType,
      'carpoolId': carpoolId,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = 'added';
    final useCase = AddPickupUseCase(repo);
    final r = await useCase(
      studentCode: 'S1',
      firstName: 'Grace',
      lastName: 'Hopper',
      email: 'grace@example.com',
      phoneNumber: '555',
      relation: 'AUNT',
      relationshipDescription: 'desc',
      pickupType: 'AUTHORIZED',
      carpoolId: 'CP1',
    );
    expect(r, 'added');
    final call = repo.calls.single;
    expect(call['studentCode'], 'S1');
    expect(call['firstName'], 'Grace');
    expect(call['relation'], 'AUNT');
    expect(call['pickupType'], 'AUTHORIZED');
    expect(call['carpoolId'], 'CP1');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = AddPickupUseCase(repo);
    expect(
      () => useCase(
        studentCode: 'S1',
        firstName: 'Grace',
        lastName: 'Hopper',
        email: 'grace@example.com',
        phoneNumber: '555',
        relation: 'AUNT',
        pickupType: 'AUTHORIZED',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
