import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/core/storage/storage_service.dart';
import 'package:wowcare/core/util/staff_code_resolver.dart';
import 'package:wowcare/core/util/storage_keys.dart';
import 'package:wowcare/domain/features/staff/usecases/get_all_staff_usecase.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_assignee.dart';
import 'package:wowcare/domain/features/tasks/entities/task_occurrence.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';
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
import 'package:wowcare/presentation/features/tasks/utils/task_timezone.dart';

part 'tasks_state.dart';

/// Lightweight assignee reference passed from the form to [TasksCubit.create].
/// Selecting several populates one shared roster on a single create call
/// (Tasks API §1); the display [name] is kept for the confirmation toast.
typedef TaskAssigneeRef = ({String code, String name});

class TasksCubit extends Cubit<TasksState> {
  TasksCubit(
    this._getTasks,
    this._createTask,
    this._deleteTask,
    this._removeAssignee,
    this._updateStatus,
    this._uploadAttachment,
    this._getAllStaff,
    this._storageService,
    this._updateAssignment,
    this._deleteAssignment,
    this._getTask,
    this._getOccurrences,
    this._updateOccurrence,
    this._cancelOccurrence,
  ) : super(const TasksState.initial());

  final GetTasksUseCase _getTasks;
  final CreateTaskUseCase _createTask;
  final DeleteTaskUseCase _deleteTask;
  final RemoveTaskAssigneeUseCase _removeAssignee;
  final UpdateTaskAssignmentStatusUseCase _updateStatus;
  final UploadTaskAttachmentUseCase _uploadAttachment;
  final GetAllStaffUseCase _getAllStaff;
  final StorageService _storageService;
  final UpdateTaskAssignmentUseCase _updateAssignment;
  final DeleteTaskAssignmentUseCase _deleteAssignment;
  final GetTaskUseCase _getTask;
  final GetTaskOccurrencesUseCase _getOccurrences;
  final UpdateTaskOccurrenceUseCase _updateOccurrence;
  final CancelTaskOccurrenceUseCase _cancelOccurrence;

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
      final schoolTimeZone = await TaskTimezone.resolve();
      emit(state.copyWith(
        scope: scope,
        tasks: _withAssigneeNames(tasks),
        isLoading: false,
        currentUserCode: userCode,
        currentUserName: userName,
        currentStaffCode: staffCode,
        schoolTimeZone: schoolTimeZone,
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

  /// Saves edits to a single card through the per-assignment endpoint (§5b
  /// `PATCH /tasks/assignments/{code}`), keyed by this card's own `TSA_` code —
  /// the single edit endpoint the backend expects the form to use, for **every**
  /// field (title, description, schedule/recurrence, priority, status, effort,
  /// assignee, attachments), not just the due date/time. Only the fields that
  /// actually changed are sent (null = unchanged), so the wire payload stays
  /// minimal. On a reassignment the roster is rebuilt from sibling cards so a
  /// full-replace never prunes other assignees. [assetCodes] full-replaces
  /// attachments (`[]` clears, a list sets, null leaves them alone).
  ///
  /// [addedAssignees] are staff picked in the edit form who weren't already on
  /// the series. They're appended to the rebuilt roster and sent as a
  /// full-replace, so the server materializes one new assignment card per added
  /// assignee (existing assignees and their cards are preserved untouched). The
  /// card being edited keeps its own assignee — this never reassigns it.
  /// Reloads on success.
  Future<bool> update(
    Task task, {
    List<String>? assetCodes,
    List<TaskAssigneeRef> addedAssignees = const [],
  }) async {
    if (task.code.isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Missing task reference'));
      return false;
    }
    final previous = state.taskByCode(task.code);
    emit(state.copyWith(isSaving: true, errorMessage: () => null));
    try {
      final titleChanged = previous == null || previous.title != task.title;
      final descriptionChanged =
          previous == null || previous.description != task.description;
      final assigneeChanged =
          previous == null || previous.assigneeCode != task.assigneeCode;
      final priorityChanged =
          previous == null || previous.priority != task.priority;
      final statusChanged = previous == null || previous.status != task.status;
      final effortChanged = previous == null || previous.effort != task.effort;
      final dueChanged = previous == null ||
          previous.dueDate != task.dueDate ||
          previous.dueTime != task.dueTime;
      final startChanged = previous == null ||
          previous.startDate != task.startDate ||
          previous.startTime != task.startTime;
      final recurrenceChanged = previous == null ||
          previous.recurring != task.recurring ||
          previous.recurringPattern != task.recurringPattern ||
          previous.recurringEndDate != task.recurringEndDate ||
          previous.startDay != task.startDay;
      final oneOff = !task.recurring;
      // New assignees added in the edit form join the series roster; a
      // reassignment swaps this card's assignee for another. Either way the
      // roster is rebuilt from sibling cards and sent as a full-replace so no
      // existing assignee is pruned.
      final hasAddedAssignees = addedAssignees.isNotEmpty;
      final rosterChanged = assigneeChanged || hasAddedAssignees;

      // One PATCH to /tasks/assignments/{code} carrying only what changed
      // (§5b). A one-off's own schedule rides the discrete occurrenceDate/
      // startTime/dueDate/dueTime fields; a recurring series' RRULE rides the
      // [schedule] Task (its per-occurrence due date/time still ride the due
      // fields). A roster change sends the rebuilt roster.
      await _updateAssignment(
        assignmentCode: task.code,
        title: titleChanged ? task.title : null,
        description: descriptionChanged ? task.description : null,
        occurrenceDate: (oneOff && startChanged) ? task.startDate : null,
        startTime: (oneOff && startChanged) ? task.startTime : null,
        dueDate: dueChanged ? task.dueDate : null,
        dueTime: dueChanged ? task.dueTime : null,
        priority: priorityChanged ? task.priority : null,
        status: statusChanged ? task.status : null,
        effort: effortChanged ? task.effort : null,
        schedule: (!oneOff && (startChanged || recurrenceChanged)) ? task : null,
        assignees: rosterChanged
            ? _rosterFor(
                task.taskCode,
                editedAssigneeCode: previous?.assigneeCode ?? task.assigneeCode,
                newAssigneeCode: task.assigneeCode,
                newPriority: task.priority,
                added: addedAssignees,
              )
            : null,
        assetCodes: assetCodes,
      );

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

  /// Inline priority change from the list view (PRD FR-TK-16). Persisted through
  /// the per-assignment endpoint (Tasks API §5b), keyed by this card's own
  /// assignment code, so it edits exactly this occurrence's priority in place.
  ///
  /// This is the backend-directed path: the per-assignee endpoint (§4b) keys off
  /// a `staffCode`, but the assignment payload round-trips `assigneeCode` with a
  /// suffix (e.g. `STF_…-0`) that doesn't match the roster, so §4b 404s. §5b
  /// uses the unambiguous `TSA_…` code instead.
  Future<void> changePriority(String code, TaskPriority priority) async {
    final task = state.taskByCode(code);
    if (task == null || task.priority == priority) return;
    await updateAssignmentDetails(code, priority: priority);
  }

  /// Edits one occurrence's own due date/time/priority in isolation (Tasks API
  /// §5b) — no effect on the series, roster default, or the assignee's other
  /// occurrences. On success the single card is replaced in place. Returns true
  /// on success.
  Future<bool> updateAssignmentDetails(
    String assignmentCode, {
    DateTime? dueDate,
    String? dueTime,
    TaskPriority? priority,
  }) async {
    if (assignmentCode.trim().isEmpty) {
      emit(state.copyWith(errorMessage: () => 'Missing task reference'));
      return false;
    }
    try {
      final updated = await _updateAssignment(
        assignmentCode: assignmentCode,
        dueDate: dueDate,
        dueTime: dueTime,
        priority: priority,
      );
      emit(state.copyWith(tasks: _replace(assignmentCode, updated)));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: () => 'Failed to update task: $e'));
      return false;
    }
  }

  /// Removes one occurrence for one assignee (Tasks API §5c). Only a `TO_DO`
  /// card can be removed this way; the server rejects others with 400, surfaced
  /// via [TasksState.errorMessage]. On success the card is dropped from state.
  /// Distinct from [removeAssignee], which drops the person from the whole series.
  Future<bool> deleteAssignment(String assignmentCode) async {
    final task = state.taskByCode(assignmentCode);
    if (task == null) {
      emit(state.copyWith(errorMessage: () => 'Missing task reference'));
      return false;
    }
    try {
      await _deleteAssignment(assignmentCode);
      emit(state.copyWith(
        tasks: state.tasks.where((t) => t.code != assignmentCode).toList(),
      ));
      return true;
    } catch (e) {
      emit(state.copyWith(errorMessage: () => 'Failed to remove task: $e'));
      return false;
    }
  }

  /// Full series detail (Tasks API §2a), including the recurrence breakdown the
  /// flat assignment cards can't provide — lets the edit form pre-populate an
  /// existing series' recurrence. Returns null on failure (non-blocking).
  Future<TaskSeries?> fetchSeriesDetail(String seriesCode) async {
    if (seriesCode.trim().isEmpty) return null;
    try {
      return await _getTask(seriesCode);
    } catch (e) {
      emit(state.copyWith(
        errorMessage: () => 'Failed to load task details: $e',
      ));
      return null;
    }
  }

  /// Every occurrence of a series, ascending (Tasks API §11a) — the only source
  /// of occurrence codes for the reschedule/cancel actions below. Returns an
  /// empty list on failure.
  Future<List<TaskOccurrence>> loadOccurrences(String seriesCode) async {
    if (seriesCode.trim().isEmpty) return const [];
    try {
      return await _getOccurrences(seriesCode);
    } catch (e) {
      emit(state.copyWith(
        errorMessage: () => 'Failed to load occurrences: $e',
      ));
      return const [];
    }
  }

  /// Reschedules/overrides a single occurrence (Tasks API §11c, THIS_ONLY). The
  /// reschedule cascades the new due moment onto that occurrence's own
  /// assignments, so the task list is reloaded on success. Returns the updated
  /// occurrence, or null on failure.
  Future<TaskOccurrence?> rescheduleOccurrence({
    required String seriesCode,
    required String occurrenceCode,
    DateTime? scheduledStartDate,
    String? scheduledStartTime,
    String? scheduledEndTime,
    String? overrideTitle,
    String? overrideDescription,
  }) async {
    try {
      final occurrence = await _updateOccurrence(
        seriesCode: seriesCode,
        occurrenceCode: occurrenceCode,
        scheduledStartDate: scheduledStartDate,
        scheduledStartTime: scheduledStartTime,
        scheduledEndTime: scheduledEndTime,
        overrideTitle: overrideTitle,
        overrideDescription: overrideDescription,
      );
      await load(silent: true);
      return occurrence;
    } catch (e) {
      emit(state.copyWith(
        errorMessage: () => 'Failed to reschedule occurrence: $e',
      ));
      return null;
    }
  }

  /// Cancels a single occurrence, keeping its row/history (Tasks API §11d).
  /// Cascades to that occurrence's untouched assignments, so the task list is
  /// reloaded on success. Returns the cancelled occurrence, or null on failure.
  Future<TaskOccurrence?> cancelOccurrence({
    required String seriesCode,
    required String occurrenceCode,
    String? reason,
  }) async {
    try {
      final occurrence = await _cancelOccurrence(
        seriesCode: seriesCode,
        occurrenceCode: occurrenceCode,
        reason: reason,
      );
      await load(silent: true);
      return occurrence;
    } catch (e) {
      emit(state.copyWith(
        errorMessage: () => 'Failed to cancel occurrence: $e',
      ));
      return null;
    }
  }

  // -------------------------------------------------------------- helpers

  /// Rebuilds the full roster for [taskCode] from the loaded cards so a
  /// single-card edit doesn't prune its siblings on a full-replace `PATCH`.
  /// The edited assignee's code/priority are overridden with the new values.
  /// [added] carries assignees newly picked in the edit form; each is appended
  /// (deduped) at the task-level [newPriority] so the server materializes a new
  /// assignment card for them without touching the existing roster.
  List<TaskAssignee> _rosterFor(
    String taskCode, {
    required String editedAssigneeCode,
    required String newAssigneeCode,
    required TaskPriority newPriority,
    List<TaskAssigneeRef> added = const [],
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
    for (final a in added) {
      if (a.code.isEmpty || !seen.add(a.code)) continue;
      roster.add(TaskAssignee(staffCode: a.code, priority: newPriority));
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
