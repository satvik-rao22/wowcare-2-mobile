import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/usecases/create_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/delete_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_tasks_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_usecase.dart';

part 'tasks_state.dart';

/// Lightweight assignee reference passed from the form to [TasksCubit.create]
/// so multi-assignee creation can fan out one task per staff member
/// (PRD BR-TASK-01) while keeping the denormalized display name.
typedef TaskAssigneeRef = ({String code, String name});

class TasksCubit extends Cubit<TasksState> {
  TasksCubit(
    this._getTasks,
    this._createTask,
    this._updateTask,
    this._deleteTask,
    this._storageService,
  ) : super(const TasksState.initial());

  final GetTasksUseCase _getTasks;
  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;
  final DeleteTaskUseCase _deleteTask;
  final StorageService _storageService;

  /// The "My Tasks" default is derived from the persona once per cubit
  /// lifetime so later loads don't clobber the user's own toggle choice.
  bool _audienceDefaultApplied = false;

  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(isLoading: true, errorMessage: () => null));
    }
    try {
      final userCode =
          (await _storageService.getString(StorageKeys.userCode) ?? '').trim();
      final userName =
          (await _storageService.getString(StorageKeys.displayName) ?? '')
              .trim();
      var staffCode =
          (await _storageService.getString(StorageKeys.staffCode) ?? '').trim();
      // Ownership ("own tasks") and the "My Tasks" scope match on the staff
      // code, so resolve it once on a cold cache (deep link / fresh session)
      // instead of relying on another screen having cached it first.
      if (staffCode.isEmpty) {
        try {
          staffCode = (await resolveStaffCodeForLoggedInUser()).trim();
        } catch (_) {}
      }
      var scope = state.scope;
      if (!_audienceDefaultApplied) {
        _audienceDefaultApplied = true;
        // Staff/teacher personas default to "For me" / "My Tasks"
        // (PRD FR-TK-19); admins default to "All Tasks".
        final role =
            (await _storageService.getString(StorageKeys.activeSchoolRole) ??
                    '')
                .toUpperCase();
        final isStaff = role.contains('STAFF') || role.contains('TEACHER');
        scope = isStaff ? TaskScope.mine : TaskScope.all;
      }
      final tasks = await _getTasks();
      emit(state.copyWith(
        scope: scope,
        tasks: tasks,
        isLoading: false,
        currentUserCode: userCode,
        currentUserName: userName,
        currentStaffCode: staffCode,
        errorMessage: () => null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: () => 'Failed to load tasks: $e',
      ));
    }
  }

  // ------------------------------------------------------ search & filters

  void setSearchQuery(String query) {
    emit(state.copyWith(searchQuery: query));
  }

  /// Scope toggle (PRD FR-TK-19): admins switch All/My, staff switch
  /// For-me/By-me.
  void setScope(TaskScope scope) {
    emit(state.copyWith(scope: scope));
  }

  void toggleAssigneeFilter(String assigneeCode) {
    final next = Set<String>.from(state.assigneeFilter);
    if (!next.remove(assigneeCode)) next.add(assigneeCode);
    emit(state.copyWith(assigneeFilter: next));
  }

  void toggleCreatedByFilter(String createdByCode) {
    final next = Set<String>.from(state.createdByFilter);
    if (!next.remove(createdByCode)) next.add(createdByCode);
    emit(state.copyWith(createdByFilter: next));
  }

  void togglePriorityFilter(TaskPriority priority) {
    final next = Set<TaskPriority>.from(state.priorityFilter);
    if (!next.remove(priority)) next.add(priority);
    emit(state.copyWith(priorityFilter: next));
  }

  void toggleStatusFilter(TaskStatus status) {
    final next = Set<TaskStatus>.from(state.statusFilter);
    if (!next.remove(status)) next.add(status);
    emit(state.copyWith(statusFilter: next));
  }

  void setDateRange({DateTime? from, DateTime? to}) {
    emit(state.copyWith(dateFrom: () => from, dateTo: () => to));
  }

  void setOverdueOnly(bool value) {
    emit(state.copyWith(overdueOnly: value));
  }

  /// Resets all filter state including the search query (PRD FR-TK-25).
  void clearAllFilters() {
    emit(state.copyWith(
      searchQuery: '',
      assigneeFilter: const <String>{},
      createdByFilter: const <String>{},
      priorityFilter: const <TaskPriority>{},
      statusFilter: const <TaskStatus>{},
      dateFrom: () => null,
      dateTo: () => null,
      overdueOnly: false,
    ));
  }

  // ----------------------------------------------------------------- tasks

  /// Creates one task per [assignees] entry (PRD BR-TASK-01: each task is
  /// identical except for the assignee). Audit/code fields are stamped here
  /// so the form only deals with user input. Returns true on success.
  Future<bool> create(Task draft, List<TaskAssigneeRef> assignees) async {
    if (assignees.isEmpty) return false;
    emit(state.copyWith(isSaving: true, errorMessage: () => null));
    try {
      final created = <Task>[];
      for (final assignee in assignees) {
        final now = DateTime.now();
        final task = draft.copyWith(
          code: 'TSK-${const Uuid().v4().substring(0, 8).toUpperCase()}',
          assigneeCode: assignee.code,
          assigneeName: assignee.name,
          createdBy: state.currentStaffCode.isNotEmpty
              ? state.currentStaffCode
              : state.currentUserCode,
          createdByName: state.currentUserName,
          createdAt: now,
          updatedAt: now,
        );
        created.add(await _createTask(task));
      }
      emit(state.copyWith(
        tasks: _sorted([...state.tasks, ...created]),
        isSaving: false,
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Failed to create task: $e',
      ));
      return false;
    }
  }

  Future<bool> update(Task task) async {
    emit(state.copyWith(isSaving: true, errorMessage: () => null));
    try {
      final updated = await _updateTask(task);
      emit(state.copyWith(tasks: _replace(updated), isSaving: false));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Failed to update task: $e',
      ));
      return false;
    }
  }

  Future<bool> delete(String code) async {
    try {
      await _deleteTask(code);
      emit(state.copyWith(
        tasks: state.tasks.where((t) => t.code != code).toList(),
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: () => 'Failed to delete task: $e'));
      return false;
    }
  }

  /// Quick status change from the Kanban tabs / card menu (PRD FR-TK-13/16).
  Future<void> changeStatus(String code, TaskStatus status) async {
    final task = state.taskByCode(code);
    if (task == null || task.status == status) return;
    await update(task.copyWith(status: status));
  }

  /// Inline priority change from the list view (PRD FR-TK-16).
  Future<void> changePriority(String code, TaskPriority priority) async {
    final task = state.taskByCode(code);
    if (task == null || task.priority == priority) return;
    await update(task.copyWith(priority: priority));
  }

  // -------------------------------------------------------------- helpers

  List<Task> _replace(Task updated) {
    return state.tasks
        .map((t) => t.code == updated.code ? updated : t)
        .toList();
  }

  static List<Task> _sorted(List<Task> tasks) {
    return tasks
      ..sort((a, b) {
        final byDue = a.dueDate.compareTo(b.dueDate);
        if (byDue != 0) return byDue;
        return a.dueTime.compareTo(b.dueTime);
      });
  }
}
