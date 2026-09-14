import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/update_student_address_request.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_address_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> updateStudentAddress({
    required String studentCode,
    required UpdateStudentAddressRequest request,
  }) async {
    calls.add({'studentCode': studentCode, 'request': request});
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const request = UpdateStudentAddressRequest(
    street: '1 Main St',
    city: 'Town',
    state: 'CA',
    country: 'US',
    postalCode: '00000',
  );

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = 'updated';
    final useCase = UpdateStudentAddressUseCase(repo);
    final r = await useCase(studentCode: 'S1', request: request);
    expect(r, 'updated');
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['request'], same(request));
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdateStudentAddressUseCase(repo);
    expect(
      () => useCase(studentCode: 'S1', request: request),
      throwsA(isA<Exception>()),
    );
  });
}
