import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/cubit/tasks_cubit.dart';

Task _card({
  required String code,
  String assignee = 'STF_1',
  String assigneeName = '',
  String createdBy = 'STF_CREATOR',
  String createdByName = '',
  TaskStatus status = TaskStatus.toDo,
  TaskPriority priority = TaskPriority.medium,
  DateTime? dueDate,
  String dueTime = '17:00',
}) =>
    Task(
      code: code,
      taskCode: 'TSK_$code',
      title: 'Task $code',
      assigneeCode: assignee,
      assigneeName: assigneeName,
      createdBy: createdBy,
      createdByName: createdByName,
      status: status,
      priority: priority,
      startDate: DateTime.utc(2026, 7, 15),
      dueDate: dueDate ?? DateTime.utc(2026, 7, 17),
      dueTime: dueTime,
      createdAt: DateTime.utc(2026),
      updatedAt: DateTime.utc(2026),
    );

TasksState _state({
  required List<Task> tasks,
  TaskScope scope = TaskScope.all,
  Set<String> assigneeFilter = const {},
  Set<String> createdByFilter = const {},
  Set<TaskPriority> priorityFilter = const {},
  Set<TaskStatus> statusFilter = const {},
  DateTime? dateFrom,
  DateTime? dateTo,
  bool overdueOnly = false,
  String currentUserCode = '',
  String currentStaffCode = '',
  TaskPersona persona = TaskPersona.admin,
}) =>
    TasksState(
      tasks: tasks,
      isLoading: false,
      isSaving: false,
      scope: scope,
      searchQuery: '',
      assigneeFilter: assigneeFilter,
      createdByFilter: createdByFilter,
      priorityFilter: priorityFilter,
      statusFilter: statusFilter,
      dateFrom: dateFrom,
      dateTo: dateTo,
      overdueOnly: overdueOnly,
      currentUserCode: currentUserCode,
      currentUserName: '',
      currentStaffCode: currentStaffCode,
      persona: persona,
    );

void main() {
  group('filteredTasks — scope', () {
    final tasks = [
      _card(code: '1', assignee: 'STF_ME', createdBy: 'STF_OTHER'),
      _card(code: '2', assignee: 'STF_OTHER', createdBy: 'STF_ME'),
      _card(code: '3', assignee: 'STF_OTHER', createdBy: 'STF_OTHER'),
    ];

    test('all shows everything', () {
      expect(_state(tasks: tasks).filteredTasks, hasLength(3));
    });

    test('mine keeps only tasks assigned to the current user', () {
      final s = _state(
        tasks: tasks,
        scope: TaskScope.mine,
        currentStaffCode: 'STF_ME',
      );
      expect(s.filteredTasks.map((t) => t.code), ['1']);
    });

    test('byMe keeps only tasks created by the current user', () {
      final s = _state(
        tasks: tasks,
        scope: TaskScope.byMe,
        currentStaffCode: 'STF_ME',
      );
      expect(s.filteredTasks.map((t) => t.code), ['2']);
    });

    test('mine/byMe fail closed while identity is unresolved', () {
      // RBAC: "my tasks" with an unknown identity must not fall back to
      // everyone's tasks (PRD §5.2) — an empty board is the safe answer.
      expect(_state(tasks: tasks, scope: TaskScope.mine).filteredTasks,
          isEmpty);
      expect(_state(tasks: tasks, scope: TaskScope.byMe).filteredTasks,
          isEmpty);
    });

    test('mine also matches on the currentUserCode', () {
      final s = _state(
        tasks: [_card(code: '1', assignee: 'USR_ME')],
        scope: TaskScope.mine,
        currentUserCode: 'USR_ME',
      );
      expect(s.filteredTasks, hasLength(1));
    });
  });

  group('visibleTasks — persona read boundary (PRD §5.2)', () {
    final tasks = [
      _card(code: '1', assignee: 'STF_ME', createdBy: 'STF_OTHER'),
      _card(code: '2', assignee: 'STF_OTHER', createdBy: 'STF_ME'),
      _card(code: '3', assignee: 'STF_OTHER', createdBy: 'STF_OTHER'),
    ];

    test('admin sees every loaded task', () {
      final s = _state(tasks: tasks, currentStaffCode: 'STF_ME');
      expect(s.visibleTasks.map((t) => t.code), ['1', '2', '3']);
    });

    test('staff sees only tasks assigned to or created by them', () {
      final s = _state(
        tasks: tasks,
        currentStaffCode: 'STF_ME',
        persona: TaskPersona.staff,
      );
      expect(s.visibleTasks.map((t) => t.code), ['1', '2']);
    });

    test('staff scope "all" cannot widen past their own tasks', () {
      final s = _state(
        tasks: tasks,
        scope: TaskScope.all,
        currentStaffCode: 'STF_ME',
        persona: TaskPersona.staff,
      );
      expect(s.filteredTasks.map((t) => t.code), ['1', '2']);
    });

    test('staff with unresolved identity sees nothing', () {
      final s = _state(tasks: tasks, persona: TaskPersona.staff);
      expect(s.visibleTasks, isEmpty);
      expect(s.filteredTasks, isEmpty);
    });

    test('filter dropdown options never leak invisible tasks', () {
      // STF_THIRD is referenced only by a task this staff member cannot see, so
      // their name must not surface in the Assignee / Created By dropdowns.
      final withThirdParty = [
        _card(code: '1', assignee: 'STF_ME', createdBy: 'STF_ME'),
        _card(code: '3', assignee: 'STF_THIRD', createdBy: 'STF_THIRD'),
      ];
      final s = _state(
        tasks: withThirdParty,
        currentStaffCode: 'STF_ME',
        persona: TaskPersona.staff,
      );
      expect(s.assigneeOptions.map((o) => o.code), <String>['STF_ME']);
      expect(s.createdByOptions.map((o) => o.code), <String>['STF_ME']);

      final adminState =
          _state(tasks: withThirdParty, currentStaffCode: 'STF_ME');
      expect(
        adminState.assigneeOptions.map((o) => o.code),
        unorderedEquals(<String>['STF_ME', 'STF_THIRD']),
      );
    });
  });

  group('filteredTasks — field filters', () {
    test('assignee filter (empty = all)', () {
      final tasks = [
        _card(code: '1', assignee: 'A'),
        _card(code: '2', assignee: 'B'),
      ];
      expect(_state(tasks: tasks).filteredTasks, hasLength(2));
      expect(
        _state(tasks: tasks, assigneeFilter: {'A'}).filteredTasks.single.code,
        '1',
      );
    });

    test('createdBy filter', () {
      final tasks = [
        _card(code: '1', createdBy: 'X'),
        _card(code: '2', createdBy: 'Y'),
      ];
      expect(
        _state(tasks: tasks, createdByFilter: {'Y'}).filteredTasks.single.code,
        '2',
      );
    });

    test('priority filter', () {
      final tasks = [
        _card(code: '1', priority: TaskPriority.high),
        _card(code: '2', priority: TaskPriority.low),
      ];
      expect(
        _state(tasks: tasks, priorityFilter: {TaskPriority.high})
            .filteredTasks
            .single
            .code,
        '1',
      );
    });

    test('status filter', () {
      final tasks = [
        _card(code: '1', status: TaskStatus.completed),
        _card(code: '2', status: TaskStatus.toDo),
      ];
      expect(
        _state(tasks: tasks, statusFilter: {TaskStatus.completed})
            .filteredTasks
            .single
            .code,
        '1',
      );
    });

    test('date-range filter is inclusive of the bounds', () {
      final tasks = [
        _card(code: 'early', dueDate: DateTime.utc(2026, 7, 10)),
        _card(code: 'mid', dueDate: DateTime.utc(2026, 7, 15)),
        _card(code: 'late', dueDate: DateTime.utc(2026, 7, 20)),
      ];
      final s = _state(
        tasks: tasks,
        dateFrom: DateTime.utc(2026, 7, 15),
        dateTo: DateTime.utc(2026, 7, 20),
      );
      expect(s.filteredTasks.map((t) => t.code), ['mid', 'late']);
    });

    test('overdueOnly keeps only overdue tasks', () {
      final tasks = [
        _card(
          code: 'overdue',
          dueDate: DateTime.utc(2000, 1, 1),
          status: TaskStatus.toDo,
        ),
        _card(
          code: 'future',
          dueDate: DateTime.utc(2999, 1, 1),
          status: TaskStatus.toDo,
        ),
      ];
      expect(
        _state(tasks: tasks, overdueOnly: true).filteredTasks.single.code,
        'overdue',
      );
    });

    test('combines multiple active filters (AND)', () {
      final tasks = [
        _card(code: '1', assignee: 'A', priority: TaskPriority.high),
        _card(code: '2', assignee: 'A', priority: TaskPriority.low),
        _card(code: '3', assignee: 'B', priority: TaskPriority.high),
      ];
      final s = _state(
        tasks: tasks,
        assigneeFilter: {'A'},
        priorityFilter: {TaskPriority.high},
      );
      expect(s.filteredTasks.single.code, '1');
    });
  });

  group('ordering', () {
    // Two overdue (past) + one future active + one completed.
    final overdueEarly = _card(
        code: 'oe', dueDate: DateTime.utc(2000, 1, 1), dueTime: '09:00');
    final overdueLate = _card(
        code: 'ol', dueDate: DateTime.utc(2000, 1, 2), dueTime: '09:00');
    final future = _card(
        code: 'f', dueDate: DateTime.utc(2999, 1, 1), status: TaskStatus.toDo);
    final doneEarly = _card(
        code: 'de',
        dueDate: DateTime.utc(2020, 1, 1),
        status: TaskStatus.completed);
    final doneLate = _card(
        code: 'dl',
        dueDate: DateTime.utc(2021, 1, 1),
        status: TaskStatus.completed);

    test('activeTasksOrdered puts overdue first, each block by due ascending',
        () {
      final s = _state(tasks: [future, overdueLate, overdueEarly]);
      expect(s.activeTasksOrdered.map((t) => t.code), ['oe', 'ol', 'f']);
    });

    test('completedTasksOrdered is most-recently-due first', () {
      final s = _state(tasks: [doneEarly, doneLate]);
      expect(s.completedTasksOrdered.map((t) => t.code), ['dl', 'de']);
    });

    test('listTasksOrdered is active (overdue-first) then completed', () {
      final s = _state(tasks: [doneEarly, future, overdueEarly, doneLate]);
      expect(s.listTasksOrdered.map((t) => t.code),
          ['oe', 'f', 'dl', 'de']);
    });

    test('orderedTasksWithStatus sorts a completed column most-recent first',
        () {
      final s = _state(tasks: [doneEarly, doneLate]);
      expect(
        s.orderedTasksWithStatus(TaskStatus.completed).map((t) => t.code),
        ['dl', 'de'],
      );
    });

    test('orderedTasksWithStatus keeps active columns overdue-first', () {
      final s = _state(tasks: [future, overdueEarly]);
      expect(
        s.orderedTasksWithStatus(TaskStatus.toDo).map((t) => t.code),
        ['oe', 'f'],
      );
    });
  });

  group('status helpers', () {
    final tasks = [
      _card(code: '1', status: TaskStatus.toDo),
      _card(code: '2', status: TaskStatus.toDo),
      _card(code: '3', status: TaskStatus.completed),
    ];

    test('tasksWithStatus / countWithStatus respect filters', () {
      final s = _state(tasks: tasks);
      expect(s.tasksWithStatus(TaskStatus.toDo), hasLength(2));
      expect(s.countWithStatus(TaskStatus.completed), 1);
    });
  });

  group('filter-option getters', () {
    test('assigneeOptions dedupes, keeps names, and sorts by name', () {
      final tasks = [
        _card(code: '1', assignee: 'B', assigneeName: 'Bravo'),
        _card(code: '2', assignee: 'A', assigneeName: 'Alpha'),
        _card(code: '3', assignee: 'A', assigneeName: 'Alpha'),
        _card(code: '4', assignee: ''),
      ];
      final opts = _state(tasks: tasks).assigneeOptions;
      expect(opts.map((o) => o.code), ['A', 'B']);
      expect(opts.first.name, 'Alpha');
    });

    test('createdByOptions falls back to the code when the name is blank', () {
      final tasks = [
        _card(code: '1', createdBy: 'STF_Z', createdByName: ''),
      ];
      final opts = _state(tasks: tasks).createdByOptions;
      expect(opts.single.code, 'STF_Z');
      expect(opts.single.name, 'STF_Z');
    });
  });

  group('filter counters', () {
    test('filterCount sums sheet filters; date range and overdue count once',
        () {
      final s = _state(
        tasks: const [],
        assigneeFilter: {'A', 'B'},
        priorityFilter: {TaskPriority.high},
        statusFilter: {TaskStatus.toDo},
        dateFrom: DateTime.utc(2026, 7, 1),
        overdueOnly: true,
      );
      // 2 assignee + 1 priority + 1 status + 1 date-range + 1 overdue = 6
      expect(s.filterCount, 6);
    });

    test('hasActiveFilters reflects sheet filters', () {
      expect(_state(tasks: const []).hasActiveFilters, isFalse);
      expect(
        _state(tasks: const [], overdueOnly: true).hasActiveFilters,
        isTrue,
      );
    });
  });

  group('taskByCode', () {
    test('finds a card by its assignment code, else null', () {
      final s = _state(tasks: [_card(code: 'TSA_9')]);
      expect(s.taskByCode('TSA_9')?.code, 'TSA_9');
      expect(s.taskByCode('missing'), isNull);
    });
  });

  group('copyWith errorNonce', () {
    test('bumps only when a non-null error is set', () {
      final base = _state(tasks: const []);
      expect(base.errorNonce, 0);

      final withError = base.copyWith(errorMessage: () => 'boom');
      expect(withError.errorNonce, 1);
      expect(withError.errorMessage, 'boom');

      // Same message again still bumps (repeat-toast behavior).
      final again = withError.copyWith(errorMessage: () => 'boom');
      expect(again.errorNonce, 2);

      // Clearing the error does not bump.
      final cleared = again.copyWith(errorMessage: () => null);
      expect(cleared.errorNonce, 2);
      expect(cleared.errorMessage, isNull);

      // An unrelated copyWith leaves the nonce and message intact.
      final unrelated = withError.copyWith(isLoading: true);
      expect(unrelated.errorNonce, 1);
      expect(unrelated.errorMessage, 'boom');
    });
  });
}
