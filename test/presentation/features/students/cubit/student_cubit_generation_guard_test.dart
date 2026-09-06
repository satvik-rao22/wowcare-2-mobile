import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/student/entities/student.dart';
import 'package:wowcare/domain/features/student/repositories/student_repository.dart';
import 'package:wowcare/domain/features/student/usecases/get_student_page_usecase.dart';
import 'package:wowcare/presentation/features/students/cubit/student_cubit.dart';

Student _student(String code) =>
    Student(code: code, firstName: code, lastName: 'L', status: 'ACTIVE');

StudentPage _page(
  List<String> codes, {
  int page = 0,
  bool hasMore = false,
}) => StudentPage(
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

/// Use case returning queued responses; a queued Completer lets a call be held
/// "in flight" and completed by the test at a controlled moment.
class _QueueUseCase extends GetStudentPageUseCase {
  _QueueUseCase() : super(_UnusedRepo());

  final List<Object> _queue = <Object>[];
  int calls = 0;

  void enqueue(Object response) => _queue.add(response);

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
  }) {
    calls++;
    final r = _queue.isNotEmpty ? _queue.removeAt(0) : _page(const []);
    if (r is Completer<StudentPage>) return r.future;
    return Future<StudentPage>.value(r as StudentPage);
  }
}

/// Storage with a mutable school code; a non-staff persona (empty role) keeps
/// the classroom-scope path a no-op (no network).
class _FakeStorage implements StorageService {
  _FakeStorage(this.schoolCode);
  String schoolCode;

  @override
  Future<String?> getString(String key) async =>
      key == StorageKeys.schoolCode ? schoolCode : null;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName} was not expected');
}

void main() {
  late _QueueUseCase useCase;
  late _FakeStorage storage;
  late StudentCubit cubit;

  StudentCubit build() => StudentCubit(
    getStudentPageUseCase: useCase,
    repository: _UnusedRepo(),
    storageService: storage,
  );

  setUp(() {
    useCase = _QueueUseCase();
    storage = _FakeStorage('SCH-A');
    cubit = build();
  });

  tearDown(() => cubit.close());

  test('happy path: refresh loads a single page into state', () async {
    useCase.enqueue(_page(['A', 'B'], hasMore: false));
    await cubit.refresh();
    expect(cubit.state.items.map((s) => s.code), ['A', 'B']);
    expect(cubit.state.isRefreshing, isFalse);
    expect(cubit.state.hasMore, isFalse);
  });

  test(
    'stale query: a refresh response superseded by a filter change is DISCARDED '
    '(covers filters the old status+search drop did not check)',
    () async {
      final gate = Completer<StudentPage>();
      useCase.enqueue(gate); // page 0 held in flight

      final future = cubit.refresh(); // captures generation G
      await Future<void>.delayed(Duration.zero);

      // A newer query begins (tag filter) before the in-flight response lands —
      // a change the legacy status+search drop did not guard.
      cubit.updateFilters(tagCodes: ['T1']);

      gate.complete(_page(['STALE'], hasMore: false));
      await future;

      // The stale page must NOT have populated the list.
      expect(cubit.state.items, isEmpty);
    },
  );

  test(
    'wrong-school: a response is DISCARDED if the active school changed mid-flight',
    () async {
      final gate = Completer<StudentPage>();
      useCase.enqueue(gate);

      final future = cubit.refresh(); // starts under SCH-A
      await Future<void>.delayed(Duration.zero);

      // School switches under the live cubit before the response lands.
      storage.schoolCode = 'SCH-B';

      gate.complete(_page(['SCH-A-STUDENT'], hasMore: false));
      await future;

      expect(cubit.state.items, isEmpty);
    },
  );

  test(
    'in-place school switch clears School A roster immediately, then loads School B',
    () async {
      // School A roster is loaded and displayed.
      useCase.enqueue(_page(['A1', 'A2'], hasMore: false));
      await cubit.refresh();
      expect(cubit.state.items.map((s) => s.code), ['A1', 'A2']);
      cubit.setSelectAll(true); // A-row selection present

      // Switch to School B, then refresh under a HELD School-B response.
      storage.schoolCode = 'SCH-B';
      final gate = Completer<StudentPage>();
      useCase.enqueue(gate);
      final future = cubit.refresh();
      await Future<void>.delayed(Duration.zero);

      // School A's roster + selection are gone at once (full loader for B) —
      // not lingering as a background refresh over the old school's data.
      expect(cubit.state.items, isEmpty);
      expect(cubit.state.selection, isEmpty);
      expect(cubit.state.status, StudentListStatus.loading);

      // School B lands and populates; no School A codes remain.
      gate.complete(_page(['B1'], hasMore: false));
      await future;
      expect(cubit.state.items.map((s) => s.code), ['B1']);
    },
  );

  test(
    'loadNextPage superseded by a filter change is DISCARDED (no cross-query append)',
    () async {
      // Seed: refresh returns page 0 (hasMore) then auto-loads page 1 (hasMore).
      useCase
        ..enqueue(_page(['A', 'B'], page: 0, hasMore: true))
        ..enqueue(_page(['C', 'D'], page: 1, hasMore: true));
      await cubit.refresh();
      expect(cubit.state.items.map((s) => s.code), ['A', 'B', 'C', 'D']);

      // load-more held in flight...
      final gate = Completer<StudentPage>();
      useCase.enqueue(gate);
      final future = cubit.loadNextPage();
      await Future<void>.delayed(Duration.zero);

      // ...a new query supersedes it before its page lands.
      cubit.updateFilters(status: 'INACTIVE');

      gate.complete(_page(['E', 'F'], page: 2, hasMore: true));
      await future;

      // The superseded page must NOT append onto the (now-stale) list.
      expect(cubit.state.items.map((s) => s.code), isNot(contains('E')));
    },
  );
}
