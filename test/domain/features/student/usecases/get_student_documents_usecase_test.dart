import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student_documents_page.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_documents_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<StudentDocumentsPage> getStudentDocuments({
    required String studentCode,
    int page = 0,
    int size = 10,
    bool? expiredOnly,
  }) async {
    calls.add({
      'studentCode': studentCode,
      'page': page,
      'size': size,
      'expiredOnly': expiredOnly,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as StudentDocumentsPage;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = StudentDocumentsPage(
    items: [],
    page: 0,
    size: 10,
    totalPages: 0,
    totalElements: 0,
    hasMore: false,
  );

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = GetStudentDocumentsUseCase(repo);
    final r = await useCase(
      studentCode: 'S1',
      page: 2,
      size: 20,
      expiredOnly: true,
    );
    expect(r, same(entity));
    expect(repo.calls.single['studentCode'], 'S1');
    expect(repo.calls.single['page'], 2);
    expect(repo.calls.single['size'], 20);
    expect(repo.calls.single['expiredOnly'], true);
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = GetStudentDocumentsUseCase(repo);
    expect(() => useCase(studentCode: 'S1'), throwsA(isA<Exception>()));
  });
}
