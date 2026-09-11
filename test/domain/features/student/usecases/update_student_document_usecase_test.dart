import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/update_student_document_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> updateStudentDocument({
    required String documentUuid,
    required String studentCode,
    required String name,
    required String type,
    required String expiryDate,
    required String storagePath,
    required String mimeType,
    required int size,
    String? assetCode,
    String? uploadedBy,
    String? notes,
  }) async {
    calls.add({
      'documentUuid': documentUuid,
      'studentCode': studentCode,
      'name': name,
      'type': type,
      'expiryDate': expiryDate,
      'storagePath': storagePath,
      'mimeType': mimeType,
      'size': size,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

Future<dynamic> _invoke(UpdateStudentDocumentUseCase useCase) => useCase(
      documentUuid: 'DOC1',
      studentCode: 'S1',
      name: 'Report',
      type: 'PDF',
      expiryDate: '2026-12-31',
      storagePath: 'path/doc.pdf',
      mimeType: 'application/pdf',
      size: 100,
    );

void main() {
  test('forwards args and returns the repository Right on success', () async {
    final repo = _FakeRepo()..result = 'ok';
    final useCase = UpdateStudentDocumentUseCase(repo);
    final r = await _invoke(useCase);
    expect(r.isRight(), isTrue);
    expect(repo.calls.single['documentUuid'], 'DOC1');
    expect(repo.calls.single['studentCode'], 'S1');
  });

  test('returns a Left when the repository fails', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = UpdateStudentDocumentUseCase(repo);
    final r = await _invoke(useCase);
    expect(r.isLeft(), isTrue);
    r.fold((l) => expect(l, isA<ServerFailure>()), (_) => fail('expected Left'));
  });
}
