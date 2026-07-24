import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_all_staff_usecase.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/entities/task_board.dart';
import 'package:wowcare/domain/features/tasks/entities/task_occurrence.dart';
import 'package:wowcare/domain/features/tasks/entities/task_query.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
import 'package:wowcare/domain/features/tasks/repositories/task_repository.dart';
import 'package:wowcare/domain/features/tasks/usecases/cancel_task_occurrence_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/create_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/delete_task_assignment_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/delete_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_task_occurrences_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_tasks_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/remove_task_assignee_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_assignment_status_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_assignment_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_occurrence_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/upload_task_attachment_usecase.dart';
import 'package:wowcare/presentation/features/tasks/cubit/tasks_cubit.dart';

/// In-memory [StorageService] so the cubit's identity/role reads never touch
/// SharedPreferences or the network staff-code resolver (a non-empty staffCode
/// short-circuits that resolver).
class _FakeStorage implements StorageService {
  final Map<String, Object> _data = {
    StorageKeys.userCode: 'USR_ME',
    StorageKeys.displayName: 'Me',
    StorageKeys.staffCode: 'STF_ME',
    StorageKeys.activeSchoolRole: 'ADMIN',
    StorageKeys.organizationCode: 'ORG_1',
    StorageKeys.schoolCode: 'SCH_1',
  };

  @override
  Future<String?> getString(String key) async => _data[key] as String?;
  @override
  Future<void> saveString(String key, String value) async => _data[key] = value;
  @override
  Future<int?> getInt(String key) async => _data[key] as int?;
  @override
  Future<void> saveInt(String key, int value) async => _data[key] = value;
  @override
  Future<bool?> getBool(String key) async => _data[key] as bool?;
  @override
  Future<void> saveBool(String key, bool value) async => _data[key] = value;
  @override
  Future<Map<String, dynamic>?> getJson(String key) async => null;
  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) async {}
  @override
  Future<void> remove(String key) async => _data.remove(key);
  @override
  Future<void> clear() async => _data.clear();
  @override
  Future<Set<String>> getKeys() async => _data.keys.toSet();
}

class _FakeTaskRepository implements TaskRepository {
  List<Task> tasks = [];

  int createCalls = 0;
  List<TaskAssignee>? lastCreateRoster;
  List<String>? lastCreateAssetCodes;
  Map<String, dynamic>? lastUpdateArgs;
  String? lastDeletedSeries;
  Map<String, dynamic>? lastRemovedAssignee;
  Map<String, dynamic>? lastStatusArgs;
  Map<String, dynamic>? lastUploadArgs;
  Map<String, dynamic>? lastAssigneePriorityArgs;
  Map<String, dynamic>? lastAssignmentPatchArgs;
  String? lastDeletedAssignment;
  String? lastFetchedTaskCode;
  Map<String, dynamic>? lastOccurrenceUpdateArgs;
  Map<String, dynamic>? lastOccurrenceCancelArgs;
  TaskSeries seriesDetail = const TaskSeries(code: 'TSK_1', title: 'x');
  List<TaskOccurrence> occurrences = const [];
  String uploadResult = 'AST_READY';

  String? lastQuery;

  @override
  Future<List<Task>> getTasks({String? query}) async {
    lastQuery = query;
    final q = (query ?? '').trim().toLowerCase();
    if (q.isEmpty) return List.of(tasks);
    return tasks.where((t) => t.title.toLowerCase().contains(q)).toList();
  }

  @override
  Future<TaskSeriesPage> getTaskSeries({
    TaskSeriesStatus? seriesStatus,
    bool? recurring,
    String? query,
    int page = 0,
    int size = 20,
  }) async =>
      const TaskSeriesPage(
        items: [],
        page: 0,
        size: 20,
        totalElements: 0,
        totalPages: 0,
      );

  @override
  Future<TaskBoard> getBoard(TaskQuery query) async => const TaskBoard.empty();

  @override
  Future<void> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
    TaskHolidayPolicy? holidayPolicy,
    List<String> assetCodes = const [],
  }) async {
    createCalls++;
    lastCreateRoster = assignees;
    lastCreateAssetCodes = assetCodes;
  }

  @override
  Future<void> updateTask({
    required String seriesCode,
    String? title,
    String? description,
    TaskHolidayPolicy? holidayPolicy,
    Task? schedule,
    List<TaskAssignee>? assignees,
    List<String>? assetCodes,
    String? parentTaskCode,
    TaskUpdateScope scope = TaskUpdateScope.all,
    String? anchorOccurrenceCode,
  }) async {
    lastUpdateArgs = {
      'seriesCode': seriesCode,
      'title': title,
      'description': description,
      'schedule': schedule,
      'assignees': assignees,
      'assetCodes': assetCodes,
      'parentTaskCode': parentTaskCode,
      'scope': scope,
      'anchorOccurrenceCode': anchorOccurrenceCode,
    };
  }

  @override
  Future<TaskSeries> getTask(String seriesCode) async {
    lastFetchedTaskCode = seriesCode;
    return seriesDetail;
  }

  @override
  Future<void> deleteTask(String seriesCode) async {
    lastDeletedSeries = seriesCode;
    // Mirror the server: the series' cards are gone on the next fetch.
    tasks = tasks.where((t) => t.taskCode != seriesCode).toList();
  }

  @override
  Future<void> removeAssignee({
    required String seriesCode,
    required String staffCode,
  }) async {
    lastRemovedAssignee = {'seriesCode': seriesCode, 'staffCode': staffCode};
    // Mirror the server: that assignee's cards are gone on the next fetch.
    tasks = tasks
        .where((t) => !(t.taskCode == seriesCode && t.assigneeCode == staffCode))
        .toList();
  }

  @override
  Future<void> updateAssigneePriority({
    required String seriesCode,
    required String staffCode,
    required TaskPriority priority,
  }) async {
    lastAssigneePriorityArgs = {
      'seriesCode': seriesCode,
      'staffCode': staffCode,
      'priority': priority,
    };
    // Mirror the §4b cascade: bump every loaded card for that assignee+series.
    tasks = tasks
        .map((t) => (t.taskCode == seriesCode && t.assigneeCode == staffCode)
            ? t.copyWith(priority: priority)
            : t)
        .toList();
  }

  @override
  Future<Task> updateAssignmentStatus({
    required String assignmentCode,
    required TaskStatus status,
  }) async {
    lastStatusArgs = {'code': assignmentCode, 'status': status};
    final current = tasks.firstWhere((t) => t.code == assignmentCode);
    return current.copyWith(status: status);
  }

  @override
  Future<Task> getAssignment(String assignmentCode) async {
    return tasks.firstWhere((t) => t.code == assignmentCode);
  }

  @override
  Future<Task> updateAssignment({
    required String assignmentCode,
    String? title,
    String? description,
    DateTime? occurrenceDate,
    String? startTime,
    DateTime? dueDate,
    String? dueTime,
    TaskPriority? priority,
    TaskStatus? status,
    double? effort,
    Task? schedule,
    List<TaskAssignee>? assignees,
    List<String>? assetCodes,
  }) async {
    lastAssignmentPatchArgs = {
      'code': assignmentCode,
      'title': title,
      'description': description,
      'occurrenceDate': occurrenceDate,
      'startTime': startTime,
      'dueDate': dueDate,
      'dueTime': dueTime,
      'priority': priority,
      'status': status,
      'effort': effort,
      'schedule': schedule,
      'assignees': assignees,
      'assetCodes': assetCodes,
    };
    final current = tasks.firstWhere((t) => t.code == assignmentCode);
    return current.copyWith(
      title: title ?? current.title,
      priority: priority ?? current.priority,
      status: status ?? current.status,
    );
  }

  @override
  Future<void> deleteAssignment(String assignmentCode) async {
    lastDeletedAssignment = assignmentCode;
  }

  @override
  Future<List<TaskOccurrence>> getOccurrences(String seriesCode) async {
    lastFetchedTaskCode = seriesCode;
    return occurrences;
  }

  @override
  Future<TaskOccurrence> getOccurrence({
    required String seriesCode,
    required String occurrenceCode,
  }) async =>
      occurrences.firstWhere((o) => o.code == occurrenceCode);

  @override
  Future<TaskOccurrence> updateOccurrence({
    required String seriesCode,
    required String occurrenceCode,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
    String? overrideTitle,
    String? overrideDescription,
  }) async {
    lastOccurrenceUpdateArgs = {
      'seriesCode': seriesCode,
      'occurrenceCode': occurrenceCode,
      'scheduledStartDate': scheduledStartDate,
      'overrideTitle': overrideTitle,
    };
    return TaskOccurrence(
      code: occurrenceCode,
      taskCode: seriesCode,
      originalStartDate: DateTime(2026, 7, 17),
      scheduledStartDate: scheduledStartDate,
      overrideTitle: overrideTitle,
      isModified: true,
    );
  }

  @override
  Future<TaskOccurrence> cancelOccurrence({
    required String seriesCode,
    required String occurrenceCode,
    String? reason,
  }) async {
    lastOccurrenceCancelArgs = {
      'seriesCode': seriesCode,
      'occurrenceCode': occurrenceCode,
      'reason': reason,
    };
    return TaskOccurrence(
      code: occurrenceCode,
      taskCode: seriesCode,
      originalStartDate: DateTime(2026, 7, 17),
      status: TaskOccurrenceStatus.cancelled,
      statusReason: reason,
    );
  }

  @override
  Future<String> uploadAttachment({
    required String filePath,
    required String fileName,
    required String contentType,
  }) async {
    lastUploadArgs = {
      'filePath': filePath,
      'fileName': fileName,
      'contentType': contentType,
    };
    return uploadResult;
  }
}

/// Minimal [StaffRepository] fake: only [getAllStaff] is exercised (name
/// enrichment); everything else throws via [noSuchMethod].
class _FakeStaffRepository implements StaffRepository {
  _FakeStaffRepository(this.staff);
  final List<StaffMember> staff;

  @override
  Future<List<StaffMember>> getAllStaff({
    required String organizationCode,
    required String schoolCode,
    List<String>? statuses,
    int size = 200,
  }) async =>
      staff;

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

StaffMember _staff(String code, String name) => StaffMember(
      code: code,
      name: name,
      primaryClassroomCode: '',
      allowedClassroomCodes: const [],
      designation: '',
      phoneNumber: '',
      status: 'ACTIVE',
      email: '',
    );

Task _card({
  required String code,
  required String taskCode,
  String assignee = 'STF_1',
  TaskStatus status = TaskStatus.toDo,
  TaskPriority priority = TaskPriority.medium,
}) =>
    Task(
      code: code,
      taskCode: taskCode,
      title: 'Task $code',
      assigneeCode: assignee,
      status: status,
      priority: priority,
      startDate: DateTime(2026, 7, 15),
      dueDate: DateTime(2026, 7, 17),
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

TasksCubit _buildCubit(
  _FakeTaskRepository repo, {
  List<StaffMember> staff = const [],
}) =>
    TasksCubit(
      GetTasksUseCase(repo),
      CreateTaskUseCase(repo),
      DeleteTaskUseCase(repo),
      RemoveTaskAssigneeUseCase(repo),
      UpdateTaskAssignmentStatusUseCase(repo),
      UploadTaskAttachmentUseCase(repo),
      GetAllStaffUseCase(_FakeStaffRepository(staff)),
      _FakeStorage(),
      UpdateTaskAssignmentUseCase(repo),
      DeleteTaskAssignmentUseCase(repo),
      GetTaskUseCase(repo),
      GetTaskOccurrencesUseCase(repo),
      UpdateTaskOccurrenceUseCase(repo),
      CancelTaskOccurrenceUseCase(repo),
    );

void main() {
  late _FakeTaskRepository repo;
  late TasksCubit cubit;

  setUp(() {
    repo = _FakeTaskRepository();
    cubit = _buildCubit(repo);
  });

  tearDown(() => cubit.close());

  test('load fetches tasks and defaults an admin to the "all" scope', () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
    await cubit.load();
    expect(cubit.state.tasks, hasLength(1));
    expect(cubit.state.scope, TaskScope.all);
    expect(cubit.state.isLoading, isFalse);
  });

  test('load resolves assignee names from the staff directory', () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_1')];
    cubit = _buildCubit(repo, staff: [_staff('STF_1', 'Alice Ng')]);

    await cubit.load();

    // The assignments API returns only a staff code; the cubit denormalizes
    // the display name so cards/detail don't show "Unassigned".
    expect(cubit.state.taskByCode('TSA_1')!.assigneeName, 'Alice Ng');
  });

  test('create sends one roster and reloads to pick up new cards', () async {
    await cubit.load();
    // After create the server has materialized two assignment cards.
    repo.tasks = [
      _card(code: 'TSA_1', taskCode: 'TSK_NEW'),
      _card(code: 'TSA_2', taskCode: 'TSK_NEW', assignee: 'STF_2'),
    ];

    final ok = await cubit.create(
      _card(code: '', taskCode: ''),
      const [(code: 'STF_1', name: 'One'), (code: 'STF_2', name: 'Two')],
    );

    expect(ok, isTrue);
    expect(repo.createCalls, 1); // single create, not one-per-assignee
    expect(repo.lastCreateRoster, hasLength(2));
    expect(cubit.state.tasks, hasLength(2));
    expect(cubit.state.isSaving, isFalse);
  });

  test('setSearchQuery refetches server-side with the query', () async {
    repo.tasks = [
      _card(code: 'TSA_1', taskCode: 'TSK_1'), // title "Task TSA_1"
      _card(code: 'TSA_2', taskCode: 'TSK_2'), // title "Task TSA_2"
    ];
    await cubit.load();
    expect(cubit.state.tasks, hasLength(2));

    cubit.setSearchQuery('TSA_1');
    await pumpEventQueue();

    expect(repo.lastQuery, 'TSA_1');
    expect(cubit.state.tasks.map((t) => t.code), ['TSA_1']);
  });

  test('changeStatus hits the assignment endpoint and updates the card', () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
    await cubit.load();

    await cubit.changeStatus('TSA_1', TaskStatus.completed);

    expect(repo.lastStatusArgs, {'code': 'TSA_1', 'status': TaskStatus.completed});
    expect(cubit.state.taskByCode('TSA_1')!.status, TaskStatus.completed);
  });

  test('delete removes every loaded card of the series via its series code', () async {
    repo.tasks = [
      _card(code: 'TSA_1', taskCode: 'TSK_1'),
      _card(code: 'TSA_2', taskCode: 'TSK_1', assignee: 'STF_2'),
      _card(code: 'TSA_3', taskCode: 'TSK_2'),
    ];
    await cubit.load();

    final ok = await cubit.delete('TSA_1');

    expect(ok, isTrue);
    expect(repo.lastDeletedSeries, 'TSK_1'); // series code, not the card code
    expect(cubit.state.tasks.map((t) => t.code), ['TSA_3']);
  });

  test('changePriority routes through the per-assignment endpoint (§5b)',
      () async {
    repo.tasks = [
      _card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_1'),
      _card(code: 'TSA_2', taskCode: 'TSK_1', assignee: 'STF_2'),
    ];
    await cubit.load();

    await cubit.changePriority('TSA_1', TaskPriority.high);

    // Backend-directed path: §5b keyed by this card's own assignment code.
    // The per-assignee §4b endpoint (broken by the suffixed assigneeCode) and
    // the old full-replace roster PATCH are never touched.
    expect(repo.lastAssignmentPatchArgs!['code'], 'TSA_1');
    expect(repo.lastAssignmentPatchArgs!['priority'], TaskPriority.high);
    expect(repo.lastAssigneePriorityArgs, isNull);
    expect(repo.lastUpdateArgs, isNull);
    // Only this card changes in place; the sibling is untouched.
    expect(cubit.state.taskByCode('TSA_1')!.priority, TaskPriority.high);
    expect(cubit.state.taskByCode('TSA_2')!.priority, TaskPriority.medium);
  });

  test('updateAssignmentDetails edits one card in place (§5b)', () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
    await cubit.load();

    final ok = await cubit.updateAssignmentDetails(
      'TSA_1',
      priority: TaskPriority.high,
    );

    expect(ok, isTrue);
    expect(repo.lastAssignmentPatchArgs!['code'], 'TSA_1');
    expect(repo.lastAssignmentPatchArgs!['priority'], TaskPriority.high);
    expect(cubit.state.taskByCode('TSA_1')!.priority, TaskPriority.high);
  });

  test('deleteAssignment drops just that card (§5c)', () async {
    repo.tasks = [
      _card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_1'),
      _card(code: 'TSA_2', taskCode: 'TSK_1', assignee: 'STF_2'),
    ];
    await cubit.load();

    final ok = await cubit.deleteAssignment('TSA_1');

    expect(ok, isTrue);
    expect(repo.lastDeletedAssignment, 'TSA_1');
    expect(cubit.state.tasks.map((t) => t.code), ['TSA_2']);
  });

  test('fetchSeriesDetail returns the full series (§2a)', () async {
    repo.seriesDetail = const TaskSeries(
      code: 'TSK_1',
      title: 'Detail',
      recurring: true,
      recurrenceByDay: ['MO', 'WE'],
    );
    await cubit.load();

    final detail = await cubit.fetchSeriesDetail('TSK_1');

    expect(repo.lastFetchedTaskCode, 'TSK_1');
    expect(detail!.recurrenceByDay, ['MO', 'WE']);
  });

  test('rescheduleOccurrence forwards THIS_ONLY overrides and reloads (§11c)',
      () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
    await cubit.load();

    final occ = await cubit.rescheduleOccurrence(
      seriesCode: 'TSK_1',
      occurrenceCode: 'TOC_7',
      scheduledStartDate: DateTime(2026, 7, 18),
      overrideTitle: 'Moved',
    );

    expect(occ!.isModified, isTrue);
    expect(repo.lastOccurrenceUpdateArgs!['occurrenceCode'], 'TOC_7');
    expect(repo.lastOccurrenceUpdateArgs!['overrideTitle'], 'Moved');
  });

  test('cancelOccurrence forwards the reason and reloads (§11d)', () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
    await cubit.load();

    final occ = await cubit.cancelOccurrence(
      seriesCode: 'TSK_1',
      occurrenceCode: 'TOC_7',
      reason: 'Closed',
    );

    expect(occ!.status, TaskOccurrenceStatus.cancelled);
    expect(repo.lastOccurrenceCancelArgs, {
      'seriesCode': 'TSK_1',
      'occurrenceCode': 'TOC_7',
      'reason': 'Closed',
    });
  });

  // Every edit-form save funnels through the per-assignment endpoint (§5b),
  // keyed by the card's own TSA_ code — the series endpoint (§3, lastUpdateArgs)
  // is never touched, no matter which field changed.
  test('update sends a title change through the assignment endpoint only',
      () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
    await cubit.load();

    final edited = cubit.state.taskByCode('TSA_1')!.copyWith(title: 'Renamed');
    final ok = await cubit.update(edited);

    expect(ok, isTrue);
    expect(repo.lastAssignmentPatchArgs!['code'], 'TSA_1');
    expect(repo.lastAssignmentPatchArgs!['title'], 'Renamed');
    expect(repo.lastUpdateArgs, isNull);
  });

  test('update sends a one-off start change as the discrete occurrence fields '
      'via the assignment endpoint', () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
    await cubit.load();

    final edited =
        cubit.state.taskByCode('TSA_1')!.copyWith(startTime: '10:00');
    final ok = await cubit.update(edited);

    expect(ok, isTrue);
    // A one-off's own schedule rides occurrenceDate/startTime (§5b), not the
    // series [schedule] Task (that only carries a recurring series' RRULE).
    expect(repo.lastAssignmentPatchArgs!['startTime'], '10:00');
    expect(repo.lastAssignmentPatchArgs!['occurrenceDate'], isNotNull);
    expect(repo.lastAssignmentPatchArgs!['schedule'], isNull);
    expect(repo.lastUpdateArgs, isNull);
  });

  test('update routes a due-only change through the assignment endpoint',
      () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
    await cubit.load();

    final edited = cubit.state
        .taskByCode('TSA_1')!
        .copyWith(dueDate: DateTime(2026, 7, 20));
    final ok = await cubit.update(edited);

    expect(ok, isTrue);
    expect(repo.lastAssignmentPatchArgs!['code'], 'TSA_1');
    expect(repo.lastAssignmentPatchArgs!['dueDate'], DateTime(2026, 7, 20));
    expect(repo.lastAssignmentPatchArgs!['dueTime'], isNotNull);
    expect(repo.lastUpdateArgs, isNull);
  });

  test('update persists a priority-only edit through the assignment endpoint',
      () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_1')];
    await cubit.load();

    final edited =
        cubit.state.taskByCode('TSA_1')!.copyWith(priority: TaskPriority.high);
    final ok = await cubit.update(edited);

    expect(ok, isTrue);
    expect(repo.lastAssignmentPatchArgs!['code'], 'TSA_1');
    expect(repo.lastAssignmentPatchArgs!['priority'], TaskPriority.high);
    expect(repo.lastUpdateArgs, isNull);
  });

  test('update forwards an attachment change via the assignment endpoint',
      () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
    await cubit.load();

    final edited = cubit.state.taskByCode('TSA_1')!;
    final ok = await cubit.update(edited, assetCodes: const ['AST_NEW']);

    expect(ok, isTrue);
    expect(repo.lastAssignmentPatchArgs!['assetCodes'], ['AST_NEW']);
    expect(repo.lastUpdateArgs, isNull);
  });

  test('update sends a reassignment roster through the assignment endpoint',
      () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_1')];
    await cubit.load();

    final edited =
        cubit.state.taskByCode('TSA_1')!.copyWith(assigneeCode: 'STF_9');
    final ok = await cubit.update(edited);

    expect(ok, isTrue);
    expect(repo.lastAssignmentPatchArgs!['assignees'], isNotNull);
    expect(repo.lastUpdateArgs, isNull);
  });

  test('update leaves the roster untouched when only a plain field changes',
      () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_1')];
    await cubit.load();

    final edited = cubit.state.taskByCode('TSA_1')!.copyWith(title: 'Renamed');
    final ok = await cubit.update(edited);

    expect(ok, isTrue);
    // No reassignment and no additions: `assignees` must stay null so the
    // server doesn't full-replace the roster on an unrelated field edit.
    expect(repo.lastAssignmentPatchArgs!['assignees'], isNull);
  });

  test('update appends added assignees to the roster and materializes their '
      'cards', () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_1')];
    await cubit.load();

    // Mirror the server: after the full-replace roster PATCH a second card is
    // materialized for the newly-added assignee.
    repo.tasks = [
      _card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_1'),
      _card(code: 'TSA_2', taskCode: 'TSK_1', assignee: 'STF_2'),
    ];

    final edited = cubit.state.taskByCode('TSA_1')!;
    final ok = await cubit.update(
      edited,
      addedAssignees: const [(code: 'STF_2', name: 'Two')],
    );

    expect(ok, isTrue);
    // The edit routes through the per-assignment endpoint keyed by this card,
    // never the series endpoint.
    expect(repo.lastAssignmentPatchArgs!['code'], 'TSA_1');
    expect(repo.lastUpdateArgs, isNull);
    // The rebuilt roster keeps the existing assignee and appends the new one.
    final roster =
        repo.lastAssignmentPatchArgs!['assignees'] as List<TaskAssignee>;
    expect(roster.map((a) => a.staffCode), containsAll(['STF_1', 'STF_2']));
    expect(roster, hasLength(2));
    // The reload picks up the new assignee's card.
    expect(cubit.state.tasks.map((t) => t.code), containsAll(['TSA_1', 'TSA_2']));
  });

  test('update dedupes an added assignee already on the series', () async {
    repo.tasks = [
      _card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_1'),
      _card(code: 'TSA_2', taskCode: 'TSK_1', assignee: 'STF_2'),
    ];
    await cubit.load();

    final edited = cubit.state.taskByCode('TSA_1')!;
    // STF_2 is already on the series; re-adding it must not duplicate the row.
    final ok = await cubit.update(
      edited,
      addedAssignees: const [(code: 'STF_2', name: 'Two')],
    );

    expect(ok, isTrue);
    final roster =
        repo.lastAssignmentPatchArgs!['assignees'] as List<TaskAssignee>;
    expect(roster.map((a) => a.staffCode), ['STF_1', 'STF_2']);
    expect(roster, hasLength(2));
  });

  test('create forwards uploaded assetCodes to the repository (§8/§9)',
      () async {
    await cubit.load();
    final ok = await cubit.create(
      _card(code: '', taskCode: ''),
      const [(code: 'STF_1', name: 'One')],
      assetCodes: const ['AST_READY'],
    );
    expect(ok, isTrue);
    expect(repo.lastCreateAssetCodes, ['AST_READY']);
  });

  test('removeAssignee drops that assignee and reloads (§4a)', () async {
    repo.tasks = [
      _card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_1'),
      _card(code: 'TSA_2', taskCode: 'TSK_1', assignee: 'STF_2'),
    ];
    await cubit.load();

    final ok = await cubit.removeAssignee('TSK_1', 'STF_2');

    expect(ok, isTrue);
    expect(repo.lastRemovedAssignee, {'seriesCode': 'TSK_1', 'staffCode': 'STF_2'});
    // Only STF_2's card is gone; STF_1 stays.
    expect(cubit.state.tasks.map((t) => t.code), ['TSA_1']);
    expect(cubit.state.isSaving, isFalse);
  });

  test('removeAssignee reports an error when references are missing', () async {
    await cubit.load();
    final ok = await cubit.removeAssignee('', 'STF_2');
    expect(ok, isFalse);
    expect(cubit.state.errorMessage, isNotNull);
  });

  test('uploadAttachment returns the ready asset code (§8/§9)', () async {
    await cubit.load();
    final code = await cubit.uploadAttachment(
      filePath: '/tmp/notes.pdf',
      fileName: 'notes.pdf',
      contentType: 'application/pdf',
    );
    expect(code, 'AST_READY');
    expect(repo.lastUploadArgs!['fileName'], 'notes.pdf');
    expect(repo.lastUploadArgs!['contentType'], 'application/pdf');
  });
}
