import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/create_guardian_user_usecase.dart';

class _FakeRepo implements StudentRepository {
  ({String message, String? guardianCode})? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<({String message, String? guardianCode})> createGuardianUser({
    required String schoolCode,
    required String studentCode,
    required String firstName,
    required String lastName,
    required String email,
    required String mobile,
    required String relationToStudent,
    required bool primaryContact,
    required bool legalCustody,
    String? profilePhotoUrl,
    String? userCode,
    String? organizationCode,
    String? relationshipDescription,
  }) async {
    calls.add({
      'schoolCode': schoolCode,
      'studentCode': studentCode,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'mobile': mobile,
      'relationToStudent': relationToStudent,
      'primaryContact': primaryContact,
      'legalCustody': legalCustody,
      'profilePhotoUrl': profilePhotoUrl,
      'userCode': userCode,
      'organizationCode': organizationCode,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const record = (message: 'created', guardianCode: 'G1');

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = record;
    final useCase = CreateGuardianUserUseCase(repo);
    final r = await useCase(
      schoolCode: 'SCH1',
      studentCode: 'S1',
      firstName: 'John',
      lastName: 'Doe',
      email: 'john@example.com',
      mobile: '555',
      relationToStudent: 'FATHER',
      primaryContact: true,
      legalCustody: false,
      profilePhotoUrl: 'url',
      userCode: 'U1',
      organizationCode: 'ORG1',
    );
    expect(r, record);
    expect(r.message, 'created');
    expect(r.guardianCode, 'G1');
    final call = repo.calls.single;
    expect(call['schoolCode'], 'SCH1');
    expect(call['studentCode'], 'S1');
    expect(call['relationToStudent'], 'FATHER');
    expect(call['primaryContact'], true);
    expect(call['legalCustody'], false);
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = CreateGuardianUserUseCase(repo);
    expect(
      () => useCase(
        schoolCode: 'SCH1',
        studentCode: 'S1',
        firstName: 'John',
        lastName: 'Doe',
        email: 'john@example.com',
        mobile: '555',
        relationToStudent: 'FATHER',
        primaryContact: true,
        legalCustody: false,
      ),
      throwsA(isA<Exception>()),
    );
  });
}
