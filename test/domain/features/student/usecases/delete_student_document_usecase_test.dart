import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/delete_student_document_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> deleteStudentDocument({
    required String documentUuid,
    required String studentCode,
  }) async {
    calls.add({'documentUuid': documentUuid, 'studentCode': studentCode});
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  test('returns the repository Right on success', () async {
    final repo = _FakeRepo()..result = 'deleted';
    final useCase = DeleteStudentDocumentUseCase(repo);
    final r = await useCase(documentUuid: 'D1', studentCode: 'S1');
    expect(r.isRight(), isTrue);
    expect(repo.calls.single['documentUuid'], 'D1');
    expect(repo.calls.single['studentCode'], 'S1');
  });

  test('returns a Left on repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = DeleteStudentDocumentUseCase(repo);
    final r = await useCase(documentUuid: 'D1', studentCode: 'S1');
    expect(r.isLeft(), isTrue);
  });
}
