import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/usecases/get_all_staff_usecase.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/usecases/create_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/delete_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/get_tasks_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/remove_task_assignee_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_assignment_status_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/update_task_usecase.dart';
import 'package:wowcare/domain/features/tasks/usecases/upload_task_attachment_usecase.dart';

part 'tasks_state.dart';

/// Lightweight assignee reference passed from the form to [TasksCubit.create].
/// Selecting several populates one shared roster on a single create call
/// (Tasks API §1); the display [name] is kept for the confirmation toast.
typedef TaskAssigneeRef = ({String code, String name});

class TasksCubit extends Cubit<TasksState> {
  TasksCubit(
    this._getTasks,
    this._createTask,
    this._updateTask,
    this._deleteTask,
    this._removeAssignee,
    this._updateStatus,
    this._uploadAttachment,
    this._getAllStaff,
    this._storageService,
  ) : super(const TasksState.initial());

  final GetTasksUseCase _getTasks;
  final CreateTaskUseCase _createTask;
  final UpdateTaskUseCase _updateTask;
  final DeleteTaskUseCase _deleteTask;
  final RemoveTaskAssigneeUseCase _removeAssignee;
  final UpdateTaskAssignmentStatusUseCase _updateStatus;
  final UploadTaskAttachmentUseCase _uploadAttachment;
  final GetAllStaffUseCase _getAllStaff;
  final StorageService _storageService;

  /// The "My Tasks" default is derived from the persona once per cubit
  /// lifetime so later loads don't clobber the user's own toggle choice.
  bool _audienceDefaultApplied = false;

  /// assigneeCode → display name, resolved from the staff directory once and
  /// reused across loads. The assignments API returns only staff codes, so we
  /// denormalize names here so cards/detail/filters read like the rest of the
  /// app instead of showing "Unassigned".
  final Map<String, String> _staffNames = {};

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
      final tasks = await _getTasks(query: state.searchQuery);
      await _ensureStaffNames();
      emit(state.copyWith(
        scope: scope,
        tasks: _withAssigneeNames(tasks),
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

  /// Search is server-backed (Tasks API §7 `q`): store the query and refetch.
  /// The UI already debounces keystrokes, so this fires at most once per pause.
  void setSearchQuery(String query) {
    if (query == state.searchQuery) return;
    emit(state.copyWith(searchQuery: query));
    _refetchForSearch();
  }

  Future<void> _refetchForSearch() async {
    final query = state.searchQuery;
    try {
      final tasks = await _getTasks(query: query);
      await _ensureStaffNames();
      // Drop a stale response if the query moved on while we were fetching.
      if (query != state.searchQuery) return;
      emit(state.copyWith(
        tasks: _withAssigneeNames(tasks),
        errorMessage: () => null,
      ));
    } catch (e) {
      if (query != state.searchQuery) return;
      emit(state.copyWith(errorMessage: () => 'Failed to search tasks: $e'));
    }
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
    final hadSearch = state.searchQuery.trim().isNotEmpty;
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
    // Clearing the text query widens the server-side search, so refetch.
    if (hadSearch) _refetchForSearch();
  }

  // ----------------------------------------------------------------- tasks

  /// Creates one task series whose roster is [assignees] (Tasks API §1 —
  /// multiple assignees populate one shared roster, not N task rows). The
  /// server stamps codes, dates and audit fields, so on success we reload to
  /// pick up the newly materialized assignment cards. Returns true on success.
  Future<bool> create(
    Task draft,
    List<TaskAssigneeRef> assignees, {
    List<String> assetCodes = const [],
  }) async {
    if (assignees.isEmpty) return false;
    emit(state.copyWith(isSaving: true, errorMessage: () => null));
    try {
      // No per-assignee priority in the form: everyone falls back to the
      // task-level priority carried on [draft].
      final roster = assignees
          .map((a) => TaskAssignee(staffCode: a.code))
          .toList();
      await _createTask(
        draft: draft,
        assignees: roster,
        assetCodes: assetCodes,
      );
      await load(silent: true);
      emit(state.copyWith(isSaving: false));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Failed to create task: $e',
      ));
      return false;
    }
  }

  /// Saves edits to a single card. Series-level fields (title/description),
  /// the schedule (dates/times/recurrence) and a full-replace roster go through
  /// `PATCH /tasks/{seriesCode}` (Tasks API §3, full parity); a status change
  /// routes through the assignment status endpoint. The schedule is only sent
  /// when it actually changed, since re-sending it re-materializes future
  /// occurrences. Reloads on success.
  Future<bool> update(Task task) async {
    if (task.taskCode.isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Missing task reference'));
      return false;
    }
    final previous = state.taskByCode(task.code);
    emit(state.copyWith(isSaving: true, errorMessage: () => null));
    try {
      final rosterChanged = previous == null ||
          previous.priority != task.priority ||
          previous.assigneeCode != task.assigneeCode;
      final scheduleChanged = previous == null ||
          previous.startDate != task.startDate ||
          previous.startTime != task.startTime ||
          previous.dueDate != task.dueDate ||
          previous.dueTime != task.dueTime ||
          previous.recurring != task.recurring ||
          previous.recurringPattern != task.recurringPattern ||
          previous.recurringEndDate != task.recurringEndDate ||
          previous.startDay != task.startDay;
      await _updateTask(
        seriesCode: task.taskCode,
        title: task.title,
        description: task.description,
        schedule: scheduleChanged ? task : null,
        assignees: rosterChanged
            ? _rosterFor(
                task.taskCode,
                editedAssigneeCode: previous?.assigneeCode ?? task.assigneeCode,
                newAssigneeCode: task.assigneeCode,
                newPriority: task.priority,
              )
            : null,
      );
      if (previous != null &&
          previous.status != task.status &&
          task.code.isNotEmpty) {
        await _updateStatus(assignmentCode: task.code, status: task.status);
      }
      await load(silent: true);
      emit(state.copyWith(isSaving: false));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Failed to update task: $e',
      ));
      return false;
    }
  }

  /// Deletes the series the card belongs to (Tasks API §4 soft-deletes the
  /// series and its untouched future assignments), then drops every loaded
  /// card of that series from state.
  Future<bool> delete(String code) async {
    final task = state.taskByCode(code);
    final seriesCode = task?.taskCode ?? '';
    if (seriesCode.isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Missing task reference'));
      return false;
    }
    try {
      await _deleteTask(seriesCode);
      // Reconcile with the server rather than optimistically dropping the
      // cards: DELETE soft-deletes the series and only its TO_DO/future
      // assignments, so a reload reflects exactly what actually remains and
      // avoids "deleted" cards reappearing on the next fetch.
      await load(silent: true);
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: () => 'Failed to delete task: $e'));
      return false;
    }
  }

  /// Removes one assignee from a task's roster (Tasks API §4a) without touching
  /// the series or other assignees, then reloads so the dropped assignee's cards
  /// disappear. Prefer this over a full-replace roster `PATCH` when the only
  /// change is dropping one person. [seriesCode] is the owning `TSK_…` code.
  Future<bool> removeAssignee(String seriesCode, String staffCode) async {
    if (seriesCode.trim().isEmpty || staffCode.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Missing task reference'));
      return false;
    }
    emit(state.copyWith(isSaving: true, errorMessage: () => null));
    try {
      await _removeAssignee(seriesCode: seriesCode, staffCode: staffCode);
      await load(silent: true);
      emit(state.copyWith(isSaving: false));
      return true;
    } catch (e) {
      emit(state.copyWith(
        isSaving: false,
        errorMessage: () => 'Failed to remove assignee: $e',
      ));
      return false;
    }
  }

  /// Uploads one attachment through the §8/§9 cross-service flow and returns the
  /// ready asset code (or null on failure), which the form then passes to
  /// [create]. Surfaces failures via [TasksState.errorMessage].
  Future<String?> uploadAttachment({
    required String filePath,
    required String fileName,
    required String contentType,
  }) async {
    try {
      return await _uploadAttachment(
        filePath: filePath,
        fileName: fileName,
        contentType: contentType,
      );
    } catch (e) {
      emit(state.copyWith(
        errorMessage: () => 'Failed to upload attachment: $e',
      ));
      return null;
    }
  }

  /// Quick status change from the Kanban tabs / card menu (PRD FR-TK-13/16).
  /// Acts directly on the single assignment (Tasks API §5).
  Future<void> changeStatus(String code, TaskStatus status) async {
    final task = state.taskByCode(code);
    if (task == null || task.status == status) return;
    try {
      final updated =
          await _updateStatus(assignmentCode: code, status: status);
      emit(state.copyWith(tasks: _replace(code, updated)));
    } catch (e) {
      emit(state.copyWith(
        errorMessage: () => 'Failed to update task: $e',
      ));
    }
  }

  /// Inline priority change from the list view (PRD FR-TK-16). Priority has no
  /// dedicated endpoint, so it is persisted by replacing the series roster
  /// (via [update]) with this assignee's new priority.
  Future<void> changePriority(String code, TaskPriority priority) async {
    final task = state.taskByCode(code);
    if (task == null || task.priority == priority) return;
    await update(task.copyWith(priority: priority));
  }

  // -------------------------------------------------------------- helpers

  /// Rebuilds the full roster for [taskCode] from the loaded cards so a
  /// single-card edit doesn't prune its siblings on a full-replace `PATCH`.
  /// The edited assignee's code/priority are overridden with the new values.
  List<TaskAssignee> _rosterFor(
    String taskCode, {
    required String editedAssigneeCode,
    required String newAssigneeCode,
    required TaskPriority newPriority,
  }) {
    final roster = <TaskAssignee>[];
    final seen = <String>{};
    for (final t in state.tasks) {
      if (t.taskCode != taskCode) continue;
      final isEdited = t.assigneeCode == editedAssigneeCode;
      final code = isEdited ? newAssigneeCode : t.assigneeCode;
      if (code.isEmpty || !seen.add(code)) continue;
      roster.add(TaskAssignee(
        staffCode: code,
        priority: isEdited ? newPriority : t.priority,
      ));
    }
    if (newAssigneeCode.isNotEmpty && seen.add(newAssigneeCode)) {
      roster.add(TaskAssignee(staffCode: newAssigneeCode, priority: newPriority));
    }
    return roster;
  }

  List<Task> _replace(String code, Task updated) {
    return state.tasks
        .map((t) => t.code == code ? _withAssigneeName(updated) : t)
        .toList();
  }

  // --------------------------------------------------- assignee-name lookup

  /// Loads the staff directory once (code → name) so [_withAssigneeName] can
  /// denormalize the assignments API's bare staff codes. Failures are
  /// swallowed — a missing name only degrades to the raw code, never blocks
  /// the task list.
  Future<void> _ensureStaffNames() async {
    if (_staffNames.isNotEmpty) return;
    try {
      final organizationCode =
          (await _storageService.getString(StorageKeys.organizationCode) ?? '')
              .trim();
      final schoolCode =
          (await _storageService.getString(StorageKeys.schoolCode) ?? '')
              .trim();
      if (organizationCode.isEmpty || schoolCode.isEmpty) return;
      final staff = await _getAllStaff(
        organizationCode: organizationCode,
        schoolCode: schoolCode,
      );
      for (final member in staff) {
        if (member.code.isNotEmpty && member.name.trim().isNotEmpty) {
          _staffNames[member.code] = member.name.trim();
        }
      }
    } catch (_) {
      // Leave names unresolved; cards fall back to the code.
    }
  }

  List<Task> _withAssigneeNames(List<Task> tasks) =>
      tasks.map(_withAssigneeName).toList();

  Task _withAssigneeName(Task task) {
    if (task.assigneeName.trim().isNotEmpty) return task;
    final name = _staffNames[task.assigneeCode];
    return name == null ? task : task.copyWith(assigneeName: name);
  }
}
