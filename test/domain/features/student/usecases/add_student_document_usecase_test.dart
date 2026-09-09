import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/add_student_document_usecase.dart';

/// The use case wraps the repository's `Future<String>` in a try/catch and
/// converts it to `Either<Failure, String>` — Right on success, Left when the
/// repository throws.
class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<String> addStudentDocument({
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
      'studentCode': studentCode,
      'name': name,
      'type': type,
      'expiryDate': expiryDate,
      'storagePath': storagePath,
      'mimeType': mimeType,
      'size': size,
      'assetCode': assetCode,
      'uploadedBy': uploadedBy,
      'notes': notes,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as String;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

Future<dynamic> _invoke(AddStudentDocumentUseCase useCase) => useCase(
      studentCode: 'S1',
      name: 'Report',
      type: 'MEDICAL',
      expiryDate: '2026-12-31',
      storagePath: 'path/doc.pdf',
      mimeType: 'application/pdf',
      size: 1024,
      assetCode: 'AST1',
      uploadedBy: 'U1',
      notes: 'n',
    );

void main() {
  test('returns the repository Right on success and forwards args', () async {
    final repo = _FakeRepo()..result = 'ok';
    final useCase = AddStudentDocumentUseCase(repo);
    final r = await _invoke(useCase);
    expect(r.isRight(), isTrue);
    final call = repo.calls.single;
    expect(call['studentCode'], 'S1');
    expect(call['name'], 'Report');
    expect(call['size'], 1024);
  });

  test('returns a Left on failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = AddStudentDocumentUseCase(repo);
    final r = await _invoke(useCase);
    expect(r.isLeft(), isTrue);
  });
}
