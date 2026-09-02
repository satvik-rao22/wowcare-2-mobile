import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/presentation/features/students/cubit/student_cubit.dart';

StudentPage _page(List<String> codes) => StudentPage(
  items: codes
      .map((c) => Student(code: c, firstName: c, lastName: 'L', status: 'ACTIVE'))
      .toList(),
  page: 0,
  size: 15,
  totalPages: 1,
  totalElements: codes.length,
  hasMore: false,
);

class _UnusedRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _CountingUseCase extends GetStudentPageUseCase {
  _CountingUseCase() : super(_UnusedRepo());
  int calls = 0;
  @override
  Future<StudentPage> call({
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
    calls++;
    return _page(['A']);
  }
}

class _FakeStorage implements StorageService {
  @override
  Future<String?> getString(String key) async =>
      key == StorageKeys.schoolCode ? 'SCH-A' : null;
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  test(
    'rapid onSearchChanged debounces to a single refresh; the query updates '
    'immediately',
    () async {
      final useCase = _CountingUseCase();
      final cubit = StudentCubit(
        getStudentPageUseCase: useCase,
        repository: _UnusedRepo(),
        storageService: _FakeStorage(),
      )..searchDebounceDelay = const Duration(milliseconds: 30);

      cubit.onSearchChanged('a');
      cubit.onSearchChanged('ab');
      cubit.onSearchChanged('abc');

      // Query reflects the latest keystroke straight away; no request yet.
      expect(cubit.state.searchQuery, 'abc');
      expect(useCase.calls, 0);

      await Future<void>.delayed(const Duration(milliseconds: 60));

      // Exactly one settled refresh fired for the whole burst.
      expect(useCase.calls, 1);
      expect(cubit.state.searchQuery, 'abc');

      await cubit.close();
    },
  );
}
