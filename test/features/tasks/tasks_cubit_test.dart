import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/core/network/api_client.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/entities/staff_member.dart';
import 'package:wowcare/domain/features/staff/repositories/staff_repository.dart';
import 'package:wowcare/domain/features/staff/usecases/get_all_staff_usecase.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/entities/task_attachment.dart';
import 'package:wowcare/domain/features/tasks/entities/task_board.dart';
import 'package:wowcare/domain/features/tasks/entities/task_occurrence.dart';
import 'package:wowcare/domain/features/tasks/entities/task_query.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
import 'package:wowcare/domain/features/tasks/repositories/task_repository.dart';
import 'package:wowcare/domain/features/tasks/usecases/cancel_task_occurrence_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/create_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/delete_task_assignment_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/delete_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/detach_task_attachment_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_task_attachments_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_task_occurrences_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_tasks_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/remove_task_assignee_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_assignment_status_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_assignment_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_occurrence_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/upload_task_attachment_usecase.dart';
import 'package:wowcare/presentation/features/tasks/cubit/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_edit_scope.dart';
import 'package:wowcare/shared/services/image_upload/image_upload_service.dart';

/// In-memory [StorageService] so the cubit's identity/role reads never touch
/// SharedPreferences or the network staff-code resolver (a non-empty staffCode
/// short-circuits that resolver).
class _FakeStorage implements StorageService {
  _FakeStorage({String activeSchoolRole = 'ADMIN'})
      : _data = {
          StorageKeys.userCode: 'USR_ME',
          StorageKeys.displayName: 'Me',
          StorageKeys.staffCode: 'STF_ME',
          StorageKeys.activeSchoolRole: activeSchoolRole,
          StorageKeys.organizationCode: 'ORG_1',
          StorageKeys.schoolCode: 'SCH_1',
        };

  final Map<String, Object> _data;

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
  Future<Map<String, dynamic>?> getJson(String key) async =>
      _json[key] == null ? null : Map<String, dynamic>.from(_json[key]!);
  @override
  Future<void> saveJson(String key, Map<String, dynamic> value) async =>
      _json[key] = Map<String, dynamic>.from(value);

  /// Real (in-memory) JSON storage, not a stub — the task attachment display
  /// cache round-trips through it.
  final Map<String, Map<String, dynamic>> _json = {};
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
  String createdSeriesCode = 'TSK_NEW';
  Map<String, dynamic>? lastUpdateArgs;
  String? lastDeletedSeries;
  Map<String, dynamic>? lastRemovedAssignee;
  Map<String, dynamic>? lastStatusArgs;
  Map<String, dynamic>? lastUploadArgs;
  Map<String, dynamic>? lastDetachArgs;
  Map<String, List<TaskAttachment>> attachments = {};
  bool attachmentsUnavailable = false;
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
  int getTasksCalls = 0;

  @override
  Future<List<Task>> getTasks({String? query}) async {
    getTasksCalls++;
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
  Future<String> createTask({
    required Task draft,
    required List<TaskAssignee> assignees,
    TaskHolidayPolicy? holidayPolicy,
    List<String> assetCodes = const [],
  }) async {
    createCalls++;
    lastCreateRoster = assignees;
    lastCreateAssetCodes = assetCodes;
    return createdSeriesCode;
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
  Future<List<String>> uploadAttachments({
    required List<PendingTaskAttachment> files,
    Map<String, String> alreadyUploaded = const {},
    void Function(String filePath, String assetCode)? onAssetUploaded,
    void Function(int index, int percent)? onProgress,
  }) async {
    lastUploadArgs = {
      'files': files,
      'alreadyUploaded': alreadyUploaded,
    };
    final codes = <String>[];
    for (var i = 0; i < files.length; i++) {
      final code = alreadyUploaded[files[i].filePath] ?? uploadResult;
      onProgress?.call(i, 100);
      onAssetUploaded?.call(files[i].filePath, code);
      codes.add(code);
    }
    return codes;
  }

  @override
  Future<List<TaskAttachment>> getAttachments(String taskCode) async {
    if (attachmentsUnavailable) throw const TaskAttachmentsUnavailable();
    return attachments[taskCode] ?? const <TaskAttachment>[];
  }

  @override
  Future<void> detachAttachment({
    required String taskCode,
    required String attachmentCode,
  }) async {
    lastDetachArgs = {
      'taskCode': taskCode,
      'attachmentCode': attachmentCode,
    };
    attachments[taskCode] = (attachments[taskCode] ?? const <TaskAttachment>[])
        .where((a) => a.code != attachmentCode)
        .toList();
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
  String activeSchoolRole = 'ADMIN',
  /// Pass the same instance to two cubits to model an app refresh: the
  /// in-memory attachment cache is gone, the on-device one is not.
  _FakeStorage? storage,
}) =>
    TasksCubit(
      GetTasksUseCase(repo),
      CreateTaskUseCase(repo),
      DeleteTaskUseCase(repo),
      RemoveTaskAssigneeUseCase(repo),
      UpdateTaskAssignmentStatusUseCase(repo),
      UploadTaskAttachmentsUseCase(repo),
      GetTaskAttachmentsUseCase(repo),
      DetachTaskAttachmentUseCase(repo),
      ImageUploadService(ApiClient(baseUrl: 'http://localhost')),
      GetAllStaffUseCase(_FakeStaffRepository(staff)),
      storage ?? _FakeStorage(activeSchoolRole: activeSchoolRole),
      UpdateTaskAssignmentUseCase(repo),
      DeleteTaskAssignmentUseCase(repo),
      GetTaskUseCase(repo),
      GetTaskOccurrencesUseCase(repo),
      UpdateTaskOccurrenceUseCase(repo),
      CancelTaskOccurrenceUseCase(repo),
      UpdateTaskUseCase(repo),
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

  test('load resolves creator names from the staff directory', () async {
    // The assignment payload carries a bare staff code for the creator, so the
    // "By Me" / "Created By" affordances would otherwise read as raw codes.
    repo.tasks = [
      _card(code: 'TSA_1', taskCode: 'TSK_1').copyWith(createdBy: 'STF_2'),
    ];
    cubit = _buildCubit(repo, staff: [_staff('STF_2', 'Bob Chen')]);

    await cubit.load();

    expect(cubit.state.tasks.single.createdByName, 'Bob Chen');
    expect(cubit.state.createdByOptions.single.name, 'Bob Chen');
  });

  test('a creator name already on the payload is left alone', () async {
    repo.tasks = [
      _card(code: 'TSA_1', taskCode: 'TSK_1')
          .copyWith(createdBy: 'STF_2', createdByName: 'From payload'),
    ];
    cubit = _buildCubit(repo, staff: [_staff('STF_2', 'Bob Chen')]);

    await cubit.load();

    expect(cubit.state.tasks.single.createdByName, 'From payload');
  });

  test('create sends one roster and reloads to pick up new cards', () async {
    await cubit.load();
    // After create the server has materialized two assignment cards.
    repo.tasks = [
      _card(code: 'TSA_1', taskCode: 'TSK_NEW'),
      _card(code: 'TSA_2', taskCode: 'TSK_NEW', assignee: 'STF_2'),
    ];

    final createdCode = await cubit.create(
      _card(code: '', taskCode: ''),
      const [(code: 'STF_1', name: 'One'), (code: 'STF_2', name: 'Two')],
    );

    // The created series code comes back so the caller can address the series
    // it just made (the reloaded cards are keyed by assignment code).
    expect(createdCode, 'TSK_NEW');
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
    final createdCode = await cubit.create(
      _card(code: '', taskCode: ''),
      const [(code: 'STF_1', name: 'One')],
      assetCodes: const ['AST_READY'],
    );
    expect(createdCode, isNotNull);
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

  test('uploadAttachments returns the ready asset codes (§8/§9)', () async {
    await cubit.load();
    final codes = await cubit.uploadAttachments(
      files: const [
        PendingTaskAttachment(
          filePath: '/tmp/notes.pdf',
          fileName: 'notes.pdf',
          contentType: 'application/pdf',
          sizeBytes: 2048,
        ),
      ],
    );
    expect(codes, ['AST_READY']);
    final sent =
        repo.lastUploadArgs!['files'] as List<PendingTaskAttachment>;
    expect(sent.single.fileName, 'notes.pdf');
    expect(sent.single.contentType, 'application/pdf');
  });

  test('uploadAttachments reuses codes from a previous attempt', () async {
    await cubit.load();
    final codes = await cubit.uploadAttachments(
      files: const [
        PendingTaskAttachment(
          filePath: '/tmp/a.pdf',
          fileName: 'a.pdf',
          contentType: 'application/pdf',
          sizeBytes: 10,
        ),
        PendingTaskAttachment(
          filePath: '/tmp/b.pdf',
          fileName: 'b.pdf',
          contentType: 'application/pdf',
          sizeBytes: 10,
        ),
      ],
      alreadyUploaded: const {'/tmp/a.pdf': 'AST_PREVIOUS'},
    );
    expect(codes, ['AST_PREVIOUS', 'AST_READY']);
  });

  test('an unreadable attachments endpoint is flagged, not reported as empty',
      () async {
    repo.attachmentsUnavailable = true;
    await cubit.load();
    await cubit.ensureAttachmentsLoaded('TSK_1');

    // Cached as empty so cards stop re-requesting it...
    expect(cubit.state.attachmentsByTask['TSK_1'], isEmpty);
    // ...but flagged, so a save never full-replaces what it could not read.
    expect(cubit.state.attachmentsAreReadable('TSK_1'), isFalse);
  });

  test('a later successful read clears the unavailable flag', () async {
    repo.attachmentsUnavailable = true;
    await cubit.load();
    await cubit.ensureAttachmentsLoaded('TSK_1');
    expect(cubit.state.attachmentsAreReadable('TSK_1'), isFalse);

    repo.attachmentsUnavailable = false;
    repo.attachments['TSK_1'] = const [
      TaskAttachment(code: 'ATT_1', assetCode: 'AST_1'),
    ];
    await cubit.refreshAttachments('TSK_1');

    expect(cubit.state.attachmentsAreReadable('TSK_1'), isTrue);
    expect(cubit.state.attachmentsByTask['TSK_1'], hasLength(1));
  });

  test('primeAttachments publishes what a save just wrote, without a read',
      () async {
    repo.attachmentsUnavailable = true;
    await cubit.load();
    await cubit.ensureAttachmentsLoaded('TSK_1');
    expect(cubit.state.attachmentsByTask['TSK_1'], isEmpty);

    cubit.primeAttachments('TSK_1', const [
      TaskAttachment(assetCode: 'AST_NEW', fileName: 'plan.pdf'),
    ]);

    // Visible immediately — the write is the source of truth here, since
    // `assetCodes` is a full replace.
    expect(cubit.state.attachmentsByTask['TSK_1']!.single.assetCode, 'AST_NEW');
    // And the set is fully known again, so the form may edit it.
    expect(cubit.state.attachmentsAreReadable('TSK_1'), isTrue);
  });

  test('a failed read never discards a primed set', () async {
    await cubit.load();
    cubit.primeAttachments('TSK_1', const [
      TaskAttachment(assetCode: 'AST_NEW'),
    ]);

    repo.attachmentsUnavailable = true;
    await cubit.refreshAttachments('TSK_1');

    expect(cubit.state.attachmentsByTask['TSK_1']!.single.assetCode, 'AST_NEW');
    expect(cubit.state.attachmentsAreReadable('TSK_1'), isTrue);
  });

  test('primed attachments survive a refresh even with no read endpoint',
      () async {
    // The exact repro: attach a file, then refresh the app and open the task.
    final storage = _FakeStorage();
    repo.attachmentsUnavailable = true;

    final first = _buildCubit(repo, storage: storage);
    await first.load();
    first.primeAttachments('TSK_1', const [
      TaskAttachment(assetCode: 'AST_NEW', fileName: 'plan.pdf'),
    ]);
    await Future<void>.delayed(Duration.zero); // let the persist land
    await first.close();

    // A fresh cubit — nothing in memory, and the read endpoint still 404s.
    final second = _buildCubit(repo, storage: storage);
    await second.load();
    await second.ensureAttachmentsLoaded('TSK_1');

    // The media is still there to render, instead of "couldn't be loaded".
    expect(second.state.attachmentsByTask['TSK_1']!.single.assetCode,
        'AST_NEW');
    // But it is not treated as authoritative: the set was never confirmed by
    // the server, so the edit form must not full-replace from it.
    expect(second.state.attachmentsAreReadable('TSK_1'), isFalse);
    await second.close();
  });

  test('a server read overrides the on-device cache', () async {
    final storage = _FakeStorage();
    final first = _buildCubit(repo, storage: storage);
    await first.load();
    first.primeAttachments('TSK_1', const [
      TaskAttachment(assetCode: 'AST_STALE'),
    ]);
    await Future<void>.delayed(Duration.zero);
    await first.close();

    repo.attachments['TSK_1'] = const [
      TaskAttachment(code: 'ATT_1', assetCode: 'AST_REAL'),
    ];
    final second = _buildCubit(repo, storage: storage);
    await second.load();
    await second.ensureAttachmentsLoaded('TSK_1');

    expect(second.state.attachmentsByTask['TSK_1']!.single.assetCode,
        'AST_REAL');
    expect(second.state.attachmentsAreReadable('TSK_1'), isTrue);
    await second.close();
  });

  test('detaching drops the row from the on-device cache too', () async {
    final storage = _FakeStorage();
    repo.attachmentsUnavailable = true;
    final first = _buildCubit(repo, storage: storage);
    await first.load();
    first.primeAttachments('TSK_1', const [
      TaskAttachment(code: 'ATT_1', assetCode: 'AST_1'),
      TaskAttachment(code: 'ATT_2', assetCode: 'AST_2'),
    ]);
    await Future<void>.delayed(Duration.zero);
    await first.detachAttachment(taskCode: 'TSK_1', attachmentCode: 'ATT_1');
    await Future<void>.delayed(Duration.zero);
    await first.close();

    final second = _buildCubit(repo, storage: storage);
    await second.load();
    await second.ensureAttachmentsLoaded('TSK_1');

    // The detached file must not come back on the next launch.
    expect(second.state.attachmentsByTask['TSK_1']!.map((a) => a.assetCode),
        ['AST_2']);
    await second.close();
  });

  test('refreshAttachments keeps the old rows visible while it refetches',
      () async {
    repo.attachments['TSK_1'] = const [
      TaskAttachment(code: 'ATT_1', assetCode: 'AST_1'),
    ];
    await cubit.load();
    await cubit.ensureAttachmentsLoaded('TSK_1');

    final future = cubit.refreshAttachments('TSK_1');
    // No emptying gap: thumbnails must not flash away and back.
    expect(cubit.state.attachmentsByTask['TSK_1'], hasLength(1));
    await future;
    expect(cubit.state.attachmentsByTask['TSK_1'], hasLength(1));
  });

  test('ensureAttachmentsLoaded caches per series and detach drops the row',
      () async {
    repo.attachments['TSK_1'] = const [
      TaskAttachment(
        code: 'ATT_1',
        assetCode: 'AST_1',
        fileName: 'plan.pdf',
        contentType: 'application/pdf',
      ),
    ];
    await cubit.load();
    await cubit.ensureAttachmentsLoaded('TSK_1');
    expect(cubit.state.attachmentsByTask['TSK_1']!.single.code, 'ATT_1');

    final ok = await cubit.detachAttachment(
      taskCode: 'TSK_1',
      attachmentCode: 'ATT_1',
    );
    expect(ok, isTrue);
    expect(repo.lastDetachArgs!['attachmentCode'], 'ATT_1');
    expect(cubit.state.attachmentsByTask['TSK_1'], isEmpty);
  });

  // ------------------------------------------------------------- persona

  group('applyPersona (PRD §5.2 read boundary)', () {
    test('staff persona defaults to "My" and marks the read boundary',
        () async {
      cubit.applyPersona('staff');
      expect(cubit.state.persona, TaskPersona.staff);
      expect(cubit.state.scope, TaskScope.mine);

      repo.tasks = [
        _card(code: 'TSA_MINE', taskCode: 'TSK_1', assignee: 'STF_ME'),
        _card(code: 'TSA_OTHER', taskCode: 'TSK_2', assignee: 'STF_OTHER'),
      ];
      await cubit.load();

      expect(cubit.state.persona, TaskPersona.staff);
      expect(cubit.state.scope, TaskScope.mine);
      // The list endpoint is not persona-filtered; the client boundary is.
      expect(cubit.state.visibleTasks.map((t) => t.code), ['TSA_MINE']);
    });

    test('admin persona defaults to "All" and keeps no read boundary',
        () async {
      cubit.applyPersona('admin');
      expect(cubit.state.persona, TaskPersona.admin);
      expect(cubit.state.scope, TaskScope.all);

      repo.tasks = [
        _card(code: 'TSA_MINE', taskCode: 'TSK_1', assignee: 'STF_ME'),
        _card(code: 'TSA_OTHER', taskCode: 'TSK_2', assignee: 'STF_OTHER'),
      ];
      await cubit.load();

      expect(cubit.state.visibleTasks, hasLength(2));
    });

    test('parent persona is treated as no-access (no tasks visible)', () async {
      cubit.applyPersona('parent');
      expect(cubit.state.persona, TaskPersona.none);
      repo.tasks = [
        _card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_ME'),
      ];
      await cubit.load();
      expect(cubit.state.persona, TaskPersona.none);
      expect(cubit.state.visibleTasks, isEmpty);
      expect(cubit.state.filteredTasks, isEmpty);
    });

    test('switching persona drops the previous session\'s cached tasks',
        () async {
      // The cubit is a singleton that outlives a logout, and the tasks route
      // reloads silently — so without this, a staff member could briefly see the
      // admin session's board (and its own identity match) before the fetch.
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_ME')];
      await cubit.load();
      expect(cubit.state.tasks, hasLength(1));
      expect(cubit.state.currentStaffCode, 'STF_ME');

      cubit.applyPersona('staff');

      expect(cubit.state.tasks, isEmpty);
      expect(cubit.state.currentUserCode, isEmpty);
      expect(cubit.state.currentStaffCode, isEmpty);
      // The new persona's toggle has different tabs, so its default is
      // re-derived rather than inheriting the admin session's "All".
      expect(cubit.state.scope, TaskScope.mine);
    });

    test('re-applying the same persona keeps the loaded board', () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      await cubit.load();
      cubit.applyPersona('admin');
      expect(cubit.state.tasks, hasLength(1));
      expect(cubit.state.currentUserCode, 'USR_ME');
    });

    test('a later load never clobbers the user\'s own scope choice', () async {
      cubit.applyPersona('staff');
      cubit.setScope(TaskScope.byMe);
      await cubit.load();
      expect(cubit.state.scope, TaskScope.byMe);
    });

    test('falls back to the stored active-school role when no persona is '
        'applied', () async {
      cubit = _buildCubit(repo, activeSchoolRole: 'STAFF');
      repo.tasks = [
        _card(code: 'TSA_MINE', taskCode: 'TSK_1', assignee: 'STF_ME'),
        _card(code: 'TSA_OTHER', taskCode: 'TSK_2', assignee: 'STF_OTHER'),
      ];

      await cubit.load();

      expect(cubit.state.scope, TaskScope.mine);
      expect(cubit.state.persona, TaskPersona.staff);
      expect(cubit.state.visibleTasks.map((t) => t.code), ['TSA_MINE']);
    });
  });

  // ------------------------------------------------ filter & scope mutators

  group('filter & scope mutators', () {
    test('setScope replaces the scope', () {
      cubit.setScope(TaskScope.mine);
      expect(cubit.state.scope, TaskScope.mine);
    });

    test('toggleAssigneeFilter adds then removes a code', () {
      cubit.toggleAssigneeFilter('STF_1');
      expect(cubit.state.assigneeFilter, {'STF_1'});
      cubit.toggleAssigneeFilter('STF_2');
      expect(cubit.state.assigneeFilter, {'STF_1', 'STF_2'});
      cubit.toggleAssigneeFilter('STF_1');
      expect(cubit.state.assigneeFilter, {'STF_2'});
    });

    test('toggleCreatedByFilter toggles membership', () {
      cubit.toggleCreatedByFilter('STF_C');
      expect(cubit.state.createdByFilter, {'STF_C'});
      cubit.toggleCreatedByFilter('STF_C');
      expect(cubit.state.createdByFilter, isEmpty);
    });

    test('togglePriorityFilter toggles membership', () {
      cubit.togglePriorityFilter(TaskPriority.high);
      expect(cubit.state.priorityFilter, {TaskPriority.high});
      cubit.togglePriorityFilter(TaskPriority.high);
      expect(cubit.state.priorityFilter, isEmpty);
    });

    test('toggleStatusFilter toggles membership', () {
      cubit.toggleStatusFilter(TaskStatus.completed);
      expect(cubit.state.statusFilter, {TaskStatus.completed});
      cubit.toggleStatusFilter(TaskStatus.completed);
      expect(cubit.state.statusFilter, isEmpty);
    });

    test('setDateRange sets and clears the range', () {
      cubit.setDateRange(
          from: DateTime(2026, 7, 1), to: DateTime(2026, 7, 31));
      expect(cubit.state.dateFrom, DateTime(2026, 7, 1));
      expect(cubit.state.dateTo, DateTime(2026, 7, 31));
      cubit.setDateRange();
      expect(cubit.state.dateFrom, isNull);
      expect(cubit.state.dateTo, isNull);
    });

    test('setOverdueOnly flips the flag', () {
      cubit.setOverdueOnly(true);
      expect(cubit.state.overdueOnly, isTrue);
      cubit.setOverdueOnly(false);
      expect(cubit.state.overdueOnly, isFalse);
    });

    test('clearAllFilters resets every filter and the search query', () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      await cubit.load();
      cubit.setSearchQuery('foo');
      await pumpEventQueue();
      cubit.toggleAssigneeFilter('STF_1');
      cubit.togglePriorityFilter(TaskPriority.high);
      cubit.setOverdueOnly(true);
      cubit.setDateRange(from: DateTime(2026, 7, 1));

      cubit.clearAllFilters();
      await pumpEventQueue();

      final s = cubit.state;
      expect(s.searchQuery, isEmpty);
      expect(s.assigneeFilter, isEmpty);
      expect(s.createdByFilter, isEmpty);
      expect(s.priorityFilter, isEmpty);
      expect(s.statusFilter, isEmpty);
      expect(s.dateFrom, isNull);
      expect(s.dateTo, isNull);
      expect(s.overdueOnly, isFalse);
      expect(s.hasActiveFilters, isFalse);
    });

    test('clearAllFilters refetches only when a search query was active',
        () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      await cubit.load();
      final callsAfterLoad = repo.getTasksCalls;

      // No search set → no refetch.
      cubit.toggleAssigneeFilter('STF_1');
      cubit.clearAllFilters();
      await pumpEventQueue();
      expect(repo.getTasksCalls, callsAfterLoad);

      // Search set → clearing widens the query, so it refetches.
      cubit.setSearchQuery('foo');
      await pumpEventQueue();
      final callsAfterSearch = repo.getTasksCalls;
      cubit.clearAllFilters();
      await pumpEventQueue();
      expect(repo.getTasksCalls, greaterThan(callsAfterSearch));
    });
  });

  // The scope the user picks in the edit-scope sheet decides which endpoint a
  // save lands on: THIS occurrence stays on the per-assignment endpoint (§5b),
  // while both series-wide scopes go to `PATCH /tasks/{code}` (§3 / §3d).
  group('update scope (recurring edit)', () {
    TaskOccurrence occurrence(String code, DateTime date) => TaskOccurrence(
          code: code,
          taskCode: 'TSK_1',
          originalStartDate: date,
          scheduledStartDate: date,
        );

    test('defaults to this-occurrence so a plain save is unchanged', () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      await cubit.load();

      final edited =
          cubit.state.taskByCode('TSA_1')!.copyWith(title: 'Renamed');
      expect(await cubit.update(edited), isTrue);

      expect(repo.lastAssignmentPatchArgs!['title'], 'Renamed');
      expect(repo.lastUpdateArgs, isNull);
    });

    test('entire series patches the series with scope ALL', () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      await cubit.load();

      final edited = cubit.state.taskByCode('TSA_1')!.copyWith(
            title: 'Renamed',
            description: 'New scope',
          );
      final ok = await cubit.update(
        edited,
        scope: TaskEditScope.entireSeries,
      );

      expect(ok, isTrue);
      expect(repo.lastUpdateArgs!['seriesCode'], 'TSK_1');
      expect(repo.lastUpdateArgs!['title'], 'Renamed');
      expect(repo.lastUpdateArgs!['description'], 'New scope');
      expect(repo.lastUpdateArgs!['scope'], TaskUpdateScope.all);
      expect(repo.lastUpdateArgs!['anchorOccurrenceCode'], isNull);
      // Nothing per-assignment changed, so the card is left alone.
      expect(repo.lastAssignmentPatchArgs, isNull);
    });

    test('entire series sends the schedule only when it changed', () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      await cubit.load();

      final titleOnly =
          cubit.state.taskByCode('TSA_1')!.copyWith(title: 'Renamed');
      await cubit.update(titleOnly, scope: TaskEditScope.entireSeries);
      expect(repo.lastUpdateArgs!['schedule'], isNull);

      final rescheduled =
          cubit.state.taskByCode('TSA_1')!.copyWith(startTime: '07:30');
      await cubit.update(rescheduled, scope: TaskEditScope.entireSeries);
      expect(repo.lastUpdateArgs!['schedule'], isNotNull);
    });

    test('entire series leaves the roster alone unless it changed', () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1', assignee: 'STF_1')];
      await cubit.load();

      final renamed =
          cubit.state.taskByCode('TSA_1')!.copyWith(title: 'Renamed');
      await cubit.update(renamed, scope: TaskEditScope.entireSeries);
      expect(repo.lastUpdateArgs!['assignees'], isNull);

      final withNewAssignee = cubit.state.taskByCode('TSA_1')!;
      await cubit.update(
        withNewAssignee,
        scope: TaskEditScope.entireSeries,
        addedAssignees: const [(code: 'STF_2', name: 'Two')],
      );
      final roster = repo.lastUpdateArgs!['assignees'] as List<TaskAssignee>;
      expect(roster.map((a) => a.staffCode), containsAll(['STF_1', 'STF_2']));
    });

    test('entire series full-replaces attachments through the series', () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      await cubit.load();

      final edited = cubit.state.taskByCode('TSA_1')!;
      await cubit.update(
        edited,
        assetCodes: const ['AST_NEW'],
        scope: TaskEditScope.entireSeries,
      );

      expect(repo.lastUpdateArgs!['assetCodes'], ['AST_NEW']);
      expect(repo.lastAssignmentPatchArgs, isNull);
    });

    test(
        'a series-wide save still applies status, priority and effort to this '
        'card', () async {
      // The Tasks API has no series-level status/effort, and a top-level
      // `priority` without a roster is a no-op (§3a) — so those three land on
      // the edited card through §5b even for a series-wide scope.
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      await cubit.load();

      final edited = cubit.state.taskByCode('TSA_1')!.copyWith(
            title: 'Renamed',
            status: TaskStatus.inProgress,
            priority: TaskPriority.high,
            effort: 2.5,
          );
      final ok = await cubit.update(
        edited,
        scope: TaskEditScope.entireSeries,
      );

      expect(ok, isTrue);
      expect(repo.lastUpdateArgs!['title'], 'Renamed');
      expect(repo.lastAssignmentPatchArgs!['code'], 'TSA_1');
      expect(repo.lastAssignmentPatchArgs!['status'], TaskStatus.inProgress);
      expect(repo.lastAssignmentPatchArgs!['priority'], TaskPriority.high);
      expect(repo.lastAssignmentPatchArgs!['effort'], 2.5);
      // The series-level fields must not be resent on the card.
      expect(repo.lastAssignmentPatchArgs!['title'], isNull);
      expect(repo.lastAssignmentPatchArgs!['schedule'], isNull);
      expect(repo.lastAssignmentPatchArgs!['assignees'], isNull);
    });

    test('this-and-future anchors on the edited card\'s own occurrence',
        () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      repo.occurrences = [
        occurrence('TOC_1', DateTime(2026, 7, 13)),
        // _card()'s occurrence date (startDate) is 2026-07-15.
        occurrence('TOC_2', DateTime(2026, 7, 15)),
        occurrence('TOC_3', DateTime(2026, 7, 17)),
      ];
      await cubit.load();

      final edited =
          cubit.state.taskByCode('TSA_1')!.copyWith(startTime: '07:30');
      final ok = await cubit.update(
        edited,
        scope: TaskEditScope.thisAndFuture,
      );

      expect(ok, isTrue);
      expect(repo.lastUpdateArgs!['seriesCode'], 'TSK_1');
      expect(repo.lastUpdateArgs!['scope'], TaskUpdateScope.thisAndFuture);
      expect(repo.lastUpdateArgs!['anchorOccurrenceCode'], 'TOC_2');
      // §3d only reanchors a schedule change, so the schedule must ride along.
      expect(repo.lastUpdateArgs!['schedule'], isNotNull);
    });

    test('this-and-future matches a rescheduled occurrence on its new date',
        () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      repo.occurrences = [
        // Moved off 2026-07-14 onto the card's own date by an earlier §11c edit.
        TaskOccurrence(
          code: 'TOC_MOVED',
          taskCode: 'TSK_1',
          originalStartDate: DateTime(2026, 7, 14),
          scheduledStartDate: DateTime(2026, 7, 15),
          isModified: true,
        ),
      ];
      await cubit.load();

      final edited =
          cubit.state.taskByCode('TSA_1')!.copyWith(startTime: '07:30');
      expect(
        await cubit.update(edited, scope: TaskEditScope.thisAndFuture),
        isTrue,
      );
      expect(repo.lastUpdateArgs!['anchorOccurrenceCode'], 'TOC_MOVED');
    });

    test('this-and-future skips a cancelled occurrence on the same date',
        () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      repo.occurrences = [
        TaskOccurrence(
          code: 'TOC_CANCELLED',
          taskCode: 'TSK_1',
          originalStartDate: DateTime(2026, 7, 15),
          scheduledStartDate: DateTime(2026, 7, 15),
          status: TaskOccurrenceStatus.cancelled,
        ),
        occurrence('TOC_LIVE', DateTime(2026, 7, 15)),
      ];
      await cubit.load();

      final edited =
          cubit.state.taskByCode('TSA_1')!.copyWith(startTime: '07:30');
      expect(
        await cubit.update(edited, scope: TaskEditScope.thisAndFuture),
        isTrue,
      );
      expect(repo.lastUpdateArgs!['anchorOccurrenceCode'], 'TOC_LIVE');
    });

    test('this-and-future fails cleanly when no occurrence matches', () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      repo.occurrences = [occurrence('TOC_1', DateTime(2026, 7, 20))];
      await cubit.load();

      final edited =
          cubit.state.taskByCode('TSA_1')!.copyWith(startTime: '07:30');
      final ok = await cubit.update(
        edited,
        scope: TaskEditScope.thisAndFuture,
      );

      expect(ok, isFalse);
      expect(cubit.state.isSaving, isFalse);
      expect(cubit.state.errorMessage, isNotNull);
      // Nothing may be sent when the anchor can't be resolved (§3d requires it).
      expect(repo.lastUpdateArgs, isNull);
      expect(repo.lastAssignmentPatchArgs, isNull);
    });

    test('a series-wide save needs the owning series code', () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: '')];
      await cubit.load();

      final edited =
          cubit.state.taskByCode('TSA_1')!.copyWith(title: 'Renamed');
      final ok = await cubit.update(
        edited,
        scope: TaskEditScope.entireSeries,
      );

      expect(ok, isFalse);
      expect(cubit.state.isSaving, isFalse);
      expect(cubit.state.errorMessage, isNotNull);
      expect(repo.lastUpdateArgs, isNull);
    });

    // The flat assignment card never carries the recurrence flag, and for a
    // recurring task the form *derives* its start/due dates from the rule — so
    // both drift from the loaded card on every save. The form therefore hands in
    // a baseline (card + series recurrence) and the derived dates are ignored,
    // or a title-only edit would cascade away every future occurrence.
    group('recurring baseline', () {
      /// The pre-edit truth as the form knows it: the loaded card with the
      /// series' recurrence folded in (`TaskScheduleUtils.withSeriesSchedule`).
      Task baselineFor(Task card) => card.copyWith(
            recurring: true,
            recurringPattern: () => TaskRecurrence.weekly,
            recurringEndDate: () => DateTime(2026, 9, 30),
            startDay: () => 'MONDAY',
          );

      test('a title-only edit never resends the schedule', () async {
        repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
        await cubit.load();

        final baseline = baselineFor(cubit.state.taskByCode('TSA_1')!);
        // The recurrence-derived window the form would submit — a different
        // calendar day from this card's own occurrence date.
        final draft = baseline.copyWith(
          title: 'Renamed',
          startDate: DateTime(2026, 8, 3),
          dueDate: DateTime(2026, 8, 7),
        );

        final ok = await cubit.update(
          draft,
          scope: TaskEditScope.entireSeries,
          baseline: baseline,
        );

        expect(ok, isTrue);
        expect(repo.lastUpdateArgs!['title'], 'Renamed');
        expect(repo.lastUpdateArgs!['schedule'], isNull);
      });

      test('a real recurrence change does resend the schedule', () async {
        repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
        await cubit.load();

        final baseline = baselineFor(cubit.state.taskByCode('TSA_1')!);
        final draft = baseline.copyWith(
          recurringPattern: () => TaskRecurrence.monthly,
          startDay: () => '15',
        );

        await cubit.update(
          draft,
          scope: TaskEditScope.entireSeries,
          baseline: baseline,
        );

        expect(repo.lastUpdateArgs!['schedule'], isNotNull);
      });

      test('a start-time change does resend the schedule', () async {
        repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
        await cubit.load();

        final baseline = baselineFor(cubit.state.taskByCode('TSA_1')!);
        final draft = baseline.copyWith(startTime: '07:30');

        await cubit.update(
          draft,
          scope: TaskEditScope.entireSeries,
          baseline: baseline,
        );

        expect(repo.lastUpdateArgs!['schedule'], isNotNull);
      });

      test('this-occurrence never sends the series schedule or derived dates',
          () async {
        // "This occurrence only" must not reach the series: no rrule, and none
        // of the rule-derived start/due dates (which aren't the user's choice —
        // a recurring form has no date pickers, only recurrence fields).
        repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
        await cubit.load();

        final baseline = baselineFor(cubit.state.taskByCode('TSA_1')!);
        final draft = baseline.copyWith(
          title: 'Renamed',
          startDate: DateTime(2026, 8, 3),
          dueDate: DateTime(2026, 8, 7),
        );

        final ok = await cubit.update(draft, baseline: baseline);

        expect(ok, isTrue);
        expect(repo.lastUpdateArgs, isNull);
        expect(repo.lastAssignmentPatchArgs!['code'], 'TSA_1');
        expect(repo.lastAssignmentPatchArgs!['title'], 'Renamed');
        expect(repo.lastAssignmentPatchArgs!['schedule'], isNull);
        expect(repo.lastAssignmentPatchArgs!['occurrenceDate'], isNull);
        expect(repo.lastAssignmentPatchArgs!['dueDate'], isNull);
      });

      test('this-occurrence still carries a time change for this card',
          () async {
        repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
        await cubit.load();

        final baseline = baselineFor(cubit.state.taskByCode('TSA_1')!);
        final draft = baseline.copyWith(
          startTime: '07:30',
          dueTime: '11:15',
          startDate: DateTime(2026, 8, 3),
          dueDate: DateTime(2026, 8, 7),
        );

        await cubit.update(draft, baseline: baseline);

        expect(repo.lastAssignmentPatchArgs!['startTime'], '07:30');
        expect(repo.lastAssignmentPatchArgs!['dueTime'], '11:15');
        // Still only the times — the derived dates stay out of it.
        expect(repo.lastAssignmentPatchArgs!['occurrenceDate'], isNull);
        expect(repo.lastAssignmentPatchArgs!['dueDate'], isNull);
        expect(repo.lastAssignmentPatchArgs!['schedule'], isNull);
      });

      test('diffFor honours the same baseline', () async {
        repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
        await cubit.load();

        final baseline = baselineFor(cubit.state.taskByCode('TSA_1')!);
        final draft = baseline.copyWith(
          title: 'Renamed',
          startDate: DateTime(2026, 8, 3),
          dueDate: DateTime(2026, 8, 7),
        );

        expect(cubit.diffFor(draft, baseline: baseline).scheduleChanged, isFalse);
        // Without the baseline the card's missing recurrence flag reads as a
        // recurrence change, which is exactly what the baseline exists to fix.
        expect(cubit.diffFor(draft).scheduleChanged, isTrue);
      });
    });

    test('diffFor reports the pending change set against the loaded card',
        () async {
      repo.tasks = [_card(code: 'TSA_1', taskCode: 'TSK_1')];
      await cubit.load();

      final card = cubit.state.taskByCode('TSA_1')!;
      expect(cubit.diffFor(card).hasChanges, isFalse);
      expect(cubit.diffFor(card.copyWith(title: 'X')).scheduleChanged, isFalse);
      expect(
        cubit.diffFor(card.copyWith(startTime: '07:30')).scheduleChanged,
        isTrue,
      );
      expect(
        cubit.diffFor(card, hasAddedAssignees: true).rosterChanged,
        isTrue,
      );
    });
  });
}
