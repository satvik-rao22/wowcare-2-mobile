import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';

class _FakeRepo implements StudentRepository {
  Object? result;
  Object? errorToThrow;
  final List<Map<String, dynamic>> calls = [];

  @override
  Future<StudentPage> getStudentPage({
    required String schoolCode,
    String? code,
    String? firstName,
    String? lastName,
    String? status,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? guardianCodes,
    List<String>? attendanceStatuses,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? allowedClassroomCodes,
  }) async {
    calls.add({
      'schoolCode': schoolCode,
      'status': status,
      'page': page,
      'size': size,
    });
    if (errorToThrow != null) throw errorToThrow!;
    return result as StudentPage;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  const entity = StudentPage(
    items: <Student>[],
    page: 0,
    size: 10,
    totalPages: 0,
    totalElements: 0,
    hasMore: false,
  );

  test('forwards args to the repository and returns its result', () async {
    final repo = _FakeRepo()..result = entity;
    final useCase = GetStudentPageUseCase(repo);
    final r = await useCase(
      schoolCode: 'SCH1',
      status: 'ACTIVE',
      page: 2,
      size: 25,
    );
    expect(r, same(entity));
    expect(repo.calls.single['schoolCode'], 'SCH1');
    expect(repo.calls.single['status'], 'ACTIVE');
    expect(repo.calls.single['page'], 2);
    expect(repo.calls.single['size'], 25);
  });

  test('propagates a repository failure', () async {
    final repo = _FakeRepo()..errorToThrow = Exception('boom');
    final useCase = GetStudentPageUseCase(repo);
    expect(() => useCase(schoolCode: 'SCH1'), throwsA(isA<Exception>()));
  });
}
