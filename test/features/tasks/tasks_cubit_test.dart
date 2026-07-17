import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_all_staff_usecase.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/repositories/task_repository.dart';
import 'package:wowcare/domain/features/tasks/usecases/create_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/delete_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_tasks_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_assignment_status_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_usecase.dart';
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
  Map<String, dynamic>? lastUpdateArgs;
  String? lastDeletedSeries;
  Map<String, dynamic>? lastStatusArgs;

  String? lastQuery;

  @override
  Future<List<Task>> getTasks({String? query}) async {
    lastQuery = query;
    final q = (query ?? '').trim().toLowerCase();
    if (q.isEmpty) return List.of(tasks);
    return tasks.where((t) => t.title.toLowerCase().contains(q)).toList();
  }

  @override
  Future<void> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
  }) async {
    createCalls++;
    lastCreateRoster = assignees;
  }

  @override
  Future<void> updateTask({
    required String seriesCode,
    String? title,
    String? description,
    TaskHolidayPolicy? holidayPolicy,
    Task? schedule,
    List<TaskAssignee>? assignees,
  }) async {
    lastUpdateArgs = {
      'seriesCode': seriesCode,
      'title': title,
      'description': description,
      'schedule': schedule,
      'assignees': assignees,
    };
  }

  @override
  Future<void> deleteTask(String seriesCode) async {
    lastDeletedSeries = seriesCode;
    // Mirror the server: the series' cards are gone on the next fetch.
    tasks = tasks.where((t) => t.taskCode != seriesCode).toList();
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
      UpdateTaskUseCase(repo),
      DeleteTaskUseCase(repo),
      UpdateTaskAssignmentStatusUseCase(repo),
      GetAllStaffUseCase(_FakeStaffRepository(staff)),
      _FakeStorage(),
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

  test('changePriority replaces the roster preserving siblings', () async {
    repo.tasks = [
      _card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_1'),
      _card(code: 'TSA_2', taskCode: 'TSK_1', assignee: 'STF_2'),
    ];
    await cubit.load();

    await cubit.changePriority('TSA_1', TaskPriority.high);

    final roster = repo.lastUpdateArgs!['assignees'] as List<TaskAssignee>;
    expect(repo.lastUpdateArgs!['seriesCode'], 'TSK_1');
    // Both assignees kept; the edited one gets the new priority.
    expect(roster.map((a) => a.staffCode).toSet(), {'STF_1', 'STF_2'});
    final edited = roster.firstWhere((a) => a.staffCode == 'STF_1');
    expect(edited.priority, TaskPriority.high);
    // A priority-only edit leaves the schedule untouched, so it must not be
    // sent (re-sending it would re-materialize future occurrences).
    expect(repo.lastUpdateArgs!['schedule'], isNull);
  });

  test('update sends the schedule only when dates/times/recurrence change',
      () async {
    repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
    await cubit.load();

    final edited = cubit.state
        .taskByCode('TSA_1')!
        .copyWith(dueDate: DateTime(2026, 7, 20));
    final ok = await cubit.update(edited);

    expect(ok, isTrue);
    final schedule = repo.lastUpdateArgs!['schedule'] as Task?;
    expect(schedule, isNotNull);
    expect(schedule!.dueDate, DateTime(2026, 7, 20));
  });
}
