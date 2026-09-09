import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/utils/storage_keys.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/presentation/features/students/view_model/student_cubit.dart';

Student _student(String code) =>
    Student(code: code, firstName: code, lastName: 'L', status: 'ACTIVE');

StudentPage _page(List<String> codes, {int page = 0, bool hasMore = false}) =>
    StudentPage(
      items: codes.map(_student).toList(),
      page: page,
      size: 15,
      totalPages: hasMore ? page + 2 : page + 1,
      totalElements: codes.length,
      hasMore: hasMore,
    );

class _UnusedRepo implements StudentRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

class _QueueUseCase extends GetStudentPageUseCase {
  _QueueUseCase() : super(_UnusedRepo());
  final List<StudentPage> _queue = <StudentPage>[];
  void enqueue(StudentPage p) => _queue.add(p);

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
  }) async => _queue.isNotEmpty ? _queue.removeAt(0) : _page(const []);
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
  late _QueueUseCase useCase;
  late StudentCubit cubit;

  setUp(() {
    useCase = _QueueUseCase();
    cubit = StudentCubit(
      getStudentPageUseCase: useCase,
      repository: _UnusedRepo(),
      storageService: _FakeStorage(),
    );
  });

  tearDown(() => cubit.close());

  test('refresh: an overlapping auto-loaded page 1 is deduped by student code', () async {
    useCase
      ..enqueue(_page(['A', 'B'], page: 0, hasMore: true))
      ..enqueue(_page(['B', 'C'], page: 1, hasMore: true)); // B overlaps page 0
    await cubit.refresh();
    expect(cubit.state.items.map((s) => s.code), ['A', 'B', 'C']); // B once
  });

  test('loadNextPage: a page overlapping the current list is deduped by code', () async {
    useCase
      ..enqueue(_page(['A', 'B'], page: 0, hasMore: true))
      ..enqueue(_page(['C', 'D'], page: 1, hasMore: true));
    await cubit.refresh();
    expect(cubit.state.items.map((s) => s.code), ['A', 'B', 'C', 'D']);

    useCase.enqueue(_page(['D', 'E'], page: 2, hasMore: true)); // D overlaps
    await cubit.loadNextPage();
    expect(cubit.state.items.map((s) => s.code), ['A', 'B', 'C', 'D', 'E']); // D once
  });
}
