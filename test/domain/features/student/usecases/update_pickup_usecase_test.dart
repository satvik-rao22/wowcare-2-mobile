import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_pickup_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> updatePickup({
    required String code,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String phoneNumber,
    required String relation,
    String? clockPin,
    String? relationshipDescription,
    String? pickupType,
    String? carpoolId,
  }) async {
    calls.add({
      'code': code,
      'studentCode': studentCode,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'relation': relation,
      'clockPin': clockPin,
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
  const entity = 'updated';

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = UpdatePickupUseCase(repo);
    final r = await useCase(
      code: 'PU1',
      studentCode: 'S1',
      firstName: 'Sam',
      lastName: 'Fox',
      email: 'sam@example.com',
      phoneNumber: '555',
      relation: 'Uncle',
      clockPin: '1234',
      pickupType: 'AUTHORIZED',
    );
    expect(r, same(entity));
    expect(repo.calls.single['code'], 'PU1');
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['relation'], 'Uncle');
    expect(repo.calls.single['clockPin'], '1234');
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdatePickupUseCase(repo);
    expect(
      () => useCase(
        code: 'PU1',
        studentCode: 'S1',
        firstName: 'Sam',
        lastName: 'Fox',
        email: 'sam@example.com',
        phoneNumber: '555',
        relation: 'Uncle',
      ),
      throwsA(isA<Exception>()),
    );
  });
}
