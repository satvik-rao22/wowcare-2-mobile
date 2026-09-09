import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/presentation/features/students/view_model/student_cubit.dart';

StudentPage _emptyPage() => const StudentPage(
  items: <Student>[],
  page: 0,
  size: 15,
  totalPages: 1,
  totalElements: 0,
  hasMore: false,
);

/// Repository whose deactivateStudent blocks on a gate and counts invocations.
class _CountingRepo implements StudentRepository {
  int deactivateCalls = 0;
  final Completer<String> gate = Completer<String>();

  @override
  Future<String> deactivateStudent({
    required String code,
    required String schoolCode,
  }) {
    deactivateCalls++;
    return gate.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _PageUseCase extends GetStudentPageUseCase {
  _PageUseCase() : super(_CountingRepo());
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
  }) async => _emptyPage();
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
    'double deactivate of the same student issues exactly ONE repository call '
    '(cubit single-flight, independent of any UI disabling)',
    () async {
      final repo = _CountingRepo();
      final cubit = StudentCubit(
        getStudentPageUseCase: _PageUseCase(),
        repository: repo,
        storageService: _FakeStorage(),
      );

      // Two rapid taps on the same student's deactivate.
      final f1 = cubit.deactivateStudent('S1');
      final f2 = cubit.deactivateStudent('S1');

      // The second call is deduped to the first's in-flight future.
      expect(identical(f1, f2), isTrue);

      // Let the first operation resolve the school and reach the repository.
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(repo.deactivateCalls, 1);

      // Complete the mutation; the ensuing refresh loads an empty page.
      repo.gate.complete('deactivated');
      await Future.wait<String>([f1, f2]);

      expect(repo.deactivateCalls, 1);
      await cubit.close();
    },
  );
}
