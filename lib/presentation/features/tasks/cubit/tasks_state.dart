part of 'tasks_cubit.dart';

/// Which slice of tasks the list/board shows.
///
/// Admins toggle between [all] ("All Tasks") and [mine] ("My Tasks"). Staff
/// instead toggle between [mine] ("For me" — assigned to them) and [byMe]
/// ("By Me" — created by them). See [TasksState.filteredTasks].
enum TaskScope { all, mine, byMe }

/// The signed-in persona's task read boundary (PRD §5.2 "View All Tasks").
///
/// [admin] covers Org Admin, School Admin and CWW Super Admin (impersonation
/// lands as the impersonated school's admin) — full read across the school.
/// [staff] is Staff/Teacher — reads only tasks assigned to or created by them.
/// [none] is Guardian/Parent — no task read at all; the module, its navigation
/// entry and its data are hidden from them entirely.
enum TaskPersona { admin, staff, none }

class TasksState extends Equatable {
  const TasksState({
    required this.tasks,
    required this.isLoading,
    required this.isSaving,
    required this.scope,
    required this.searchQuery,
    required this.assigneeFilter,
    required this.createdByFilter,
    required this.priorityFilter,
    required this.statusFilter,
    this.dateFrom,
    this.dateTo,
    required this.overdueOnly,
    required this.currentUserCode,
    required this.currentUserName,
    this.currentStaffCode = '',
    this.errorMessage,
    this.errorNonce = 0,
    this.schoolTimeZone = TaskTimezone.fallbackTimeZone,
    this.persona = TaskPersona.admin,
    this.attachmentsByTask = const <String, List<TaskAttachment>>{},
    this.attachmentsUnavailable = const <String>{},
  });

  const TasksState.initial()
      : tasks = const [],
        isLoading = true,
        isSaving = false,
        scope = TaskScope.all,
        searchQuery = '',
        assigneeFilter = const <String>{},
        createdByFilter = const <String>{},
        priorityFilter = const <TaskPriority>{},
        statusFilter = const <TaskStatus>{},
        dateFrom = null,
        dateTo = null,
        overdueOnly = false,
        currentUserCode = '',
        currentUserName = '',
        currentStaffCode = '',
        errorMessage = null,
        errorNonce = 0,
        schoolTimeZone = TaskTimezone.fallbackTimeZone,
        persona = TaskPersona.admin,
        attachmentsByTask = const <String, List<TaskAttachment>>{},
        attachmentsUnavailable = const <String>{};

  final List<Task> tasks;
  final bool isLoading;
  final bool isSaving;

  /// Which slice of tasks to show (PRD FR-TK-19). Defaults to [TaskScope.mine]
  /// for staff personas, [TaskScope.all] for admins.
  final TaskScope scope;

  /// Free-text filter on title/description (PRD FR-TK-20, fires per keystroke).
  final String searchQuery;

  /// Empty sets mean "show all".
  final Set<String> assigneeFilter;
  final Set<String> createdByFilter;
  final Set<TaskPriority> priorityFilter;
  final Set<TaskStatus> statusFilter;

  /// Due-date range filter (PRD FR-TK-21).
  final DateTime? dateFrom;
  final DateTime? dateTo;

  /// Show only overdue tasks (PRD FR-TK-23).
  final bool overdueOnly;

  final String currentUserCode;
  final String currentUserName;

  /// Staff code of the logged-in user (differs from [currentUserCode]); empty
  /// before resolution. Used to match the user against task assignee/creator.
  final String currentStaffCode;
  final String? errorMessage;

  /// The current school's IANA timezone (Tasks-specific fallback: Boston),
  /// resolved on [TasksCubit.load]. Drives every date/time picker's defaults
  /// and the UTC-to-local conversion for displayed schedules.
  final String schoolTimeZone;

  /// Bumped every time [errorMessage] is set to a non-null value. Two
  /// failures in a row can produce the exact same message text (e.g. the same
  /// generic "Failed to update task" from two consecutive offline retries);
  /// listeners key off this instead of the message text so a repeat failure
  /// still re-triggers its own toast/dismiss-timer rather than being silently
  /// dropped because the text didn't change.
  final int errorNonce;

  /// The signed-in persona's read boundary (PRD §5.2), which narrows
  /// [visibleTasks] regardless of which scope the toggle is on. Set by
  /// [TasksCubit.applyPersona] from [RoleCubit] when the module opens, and
  /// derived from the stored active-school role by [TasksCubit.load] otherwise.
  /// Defaults to [TaskPersona.admin] so the board behaves exactly as before for
  /// admin sessions; staff/parent sessions are narrowed the moment the persona
  /// is known (before the first fetch resolves).
  final TaskPersona persona;

  /// Attachments keyed by **series** code (`TSK_…`), not by the card's
  /// assignment code — attachments belong to the series, so every card of the
  /// same series shares one entry and one fetch. A present-but-empty list means
  /// "loaded, has none"; an absent key means "not fetched yet".
  final Map<String, List<TaskAttachment>> attachmentsByTask;

  /// Attachments for one task card, resolved through its series code.
  ///
  /// Prefers a fetched/primed set, which carries file names, sizes and the
  /// `ATT_…` row codes needed to detach. Falls back to the card's own
  /// [Task.assetCodes] — the assignment payload's complete asset list — so
  /// attachments still render when no attachments endpoint answered. Those
  /// synthesized entries know only their asset code: the UI resolves a delivery
  /// URL from it, and cannot offer detach (no row code).
  List<TaskAttachment> attachmentsFor(Task task) {
    final loaded = attachmentsByTask[task.taskCode];
    if (loaded != null && loaded.isNotEmpty) return loaded;
    if (task.assetCodes.isEmpty) return loaded ?? const <TaskAttachment>[];
    return task.assetCodes
        .map((assetCode) => TaskAttachment(assetCode: assetCode))
        .toList(growable: false);
  }

  /// Whether this card's attachments can be shown truthfully. The card's own
  /// [Task.assetCodes] are authoritative, so a failed/absent attachments fetch
  /// no longer means "unknown" for a task that listed its assets.
  bool attachmentsReadableForTask(Task task) =>
      task.assetCodes.isNotEmpty || attachmentsAreReadable(task.taskCode);

  /// Whether this task's attachments have been fetched at least once —
  /// distinguishes "none" from "not yet known".
  bool hasLoadedAttachments(Task task) =>
      attachmentsByTask.containsKey(task.taskCode);

  /// Series codes whose attachments could not be read (no endpoint, or the
  /// request failed). Distinct from "has none": since `assetCodes` is a full
  /// replace on save, a form must not write attachments for a series in here
  /// or it would delete whatever the server holds unseen.
  final Set<String> attachmentsUnavailable;

  bool attachmentsAreReadable(String taskCode) =>
      !attachmentsUnavailable.contains(taskCode.trim());

  /// Count of active sheet filters shown on the Filters button. Search is
  /// tracked separately by [hasActiveFilters] so the search bar drives the
  /// Clear affordance without bumping this badge (PRD FR-TK-24).
  int get filterCount =>
      assigneeFilter.length +
      createdByFilter.length +
      priorityFilter.length +
      statusFilter.length +
      (dateFrom != null || dateTo != null ? 1 : 0) +
      (overdueOnly ? 1 : 0);

  bool get hasActiveFilters => filterCount > 0 || searchQuery.trim().isNotEmpty;

  /// The tasks this persona is allowed to see at all, before any scope toggle
  /// or filter (PRD §5.2 "View All Tasks"). The `/tasks/assignments` endpoint
  /// is not persona-filtered, so this is the client-side read boundary:
  ///
  /// - [TaskPersona.admin] → every loaded task.
  /// - [TaskPersona.staff] → only tasks assigned to or created by them; nothing
  ///   at all while their identity is unresolved (fail closed — never fall back
  ///   to the whole school).
  /// - [TaskPersona.none] (guardian/parent) → nothing.
  List<Task> get visibleTasks {
    switch (persona) {
      case TaskPersona.admin:
        return tasks;
      case TaskPersona.staff:
        return tasks.where((task) => _isMine(task) || _isByMe(task)).toList();
      case TaskPersona.none:
        return const [];
    }
  }

  /// Tasks passing the scope / assignee / priority / status / date / overdue
  /// filters, within [visibleTasks]. The free-text search is applied
  /// server-side (Tasks API §7 `q`), so [tasks] is already the search result
  /// set — no client-side text match here.
  ///
  /// This iterates the full list, so callers that need it several times in one
  /// build (the status tabs, the Kanban column and the list view) should
  /// compute it once and reuse it rather than reading this getter repeatedly.
  List<Task> get filteredTasks {
    final now = DateTime.now();
    return visibleTasks.where((task) {
      if (scope == TaskScope.mine && !_isMine(task)) return false;
      if (scope == TaskScope.byMe && !_isByMe(task)) return false;
      if (assigneeFilter.isNotEmpty &&
          !assigneeFilter.contains(task.assigneeCode)) {
        return false;
      }
      if (createdByFilter.isNotEmpty &&
          !createdByFilter.contains(task.createdBy)) {
        return false;
      }
      if (priorityFilter.isNotEmpty &&
          !priorityFilter.contains(task.priority)) {
        return false;
      }
      if (statusFilter.isNotEmpty && !statusFilter.contains(task.status)) {
        return false;
      }
      if (dateFrom != null && task.dueDate.isBefore(dateFrom!)) return false;
      if (dateTo != null && task.dueDate.isAfter(dateTo!)) return false;
      if (overdueOnly && !task.isOverdueAt(now)) return false;
      return true;
    }).toList();
  }

  /// Filtered tasks in a single Kanban column.
  List<Task> tasksWithStatus(TaskStatus status) =>
      filteredTasks.where((t) => t.status == status).toList();

  int countWithStatus(TaskStatus status) =>
      filteredTasks.where((t) => t.status == status).length;

  /// Tasks for a Kanban board with the required ordering: overdue items
  /// first (by due moment) on the active boards, and most-recently-due
  /// first on the Completed board (completed tasks are never overdue).
  List<Task> orderedTasksWithStatus(TaskStatus status) =>
      orderColumn(filteredTasks, status);

  /// Non-completed filtered tasks, overdue first then the rest — backs the
  /// list view's active list.
  List<Task> get activeTasksOrdered => orderActive(filteredTasks);

  /// Completed filtered tasks, most recently due first.
  List<Task> get completedTasksOrdered => orderCompleted(filteredTasks);

  /// All filtered tasks for the list view: active first (overdue first),
  /// then completed (most recently due last). The status filter narrows this
  /// when the user wants only completed (or any single status).
  List<Task> get listTasksOrdered => listFrom(filteredTasks);

  // --- Pure ordering helpers, so a build that needs several of these can run
  // [filteredTasks] once and reuse the result instead of recomputing the full
  // filter pass for each view (the list/tabs/column all read from it).

  /// Column ordering for a precomputed [filtered] list (see
  /// [orderedTasksWithStatus]).
  static List<Task> orderColumn(List<Task> filtered, TaskStatus status) {
    final list = filtered.where((t) => t.status == status).toList();
    if (status == TaskStatus.completed) {
      return list..sort((a, b) => b.dueAt.compareTo(a.dueAt));
    }
    return _overdueFirst(list);
  }

  /// Active (non-completed) tasks from a precomputed [filtered] list,
  /// overdue-first.
  static List<Task> orderActive(List<Task> filtered) => _overdueFirst(
        filtered.where((t) => t.status != TaskStatus.completed).toList(),
      );

  /// Completed tasks from a precomputed [filtered] list, most-recently-due
  /// first.
  static List<Task> orderCompleted(List<Task> filtered) =>
      filtered.where((t) => t.status == TaskStatus.completed).toList()
        ..sort((a, b) => b.dueAt.compareTo(a.dueAt));

  /// Full list-view ordering from a precomputed [filtered] list.
  static List<Task> listFrom(List<Task> filtered) =>
      [...orderActive(filtered), ...orderCompleted(filtered)];

  /// Orders [source] with overdue tasks first (by due moment), then the
  /// remaining tasks (also by due moment).
  static List<Task> _overdueFirst(List<Task> source) {
    final now = DateTime.now();
    final overdue = <Task>[];
    final rest = <Task>[];
    for (final task in source) {
      (task.isOverdueAt(now) ? overdue : rest).add(task);
    }
    overdue.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    rest.sort((a, b) => a.dueAt.compareTo(b.dueAt));
    return [...overdue, ...rest];
  }

  /// The current user's identity codes (empty entries dropped) — a task matches
  /// "mine"/"by me" on either the staff code or the user code, since the two
  /// spellings appear in different payloads. Empty while identity is still
  /// unresolved, which is what makes the ownership checks fail closed.
  ///
  /// Public so the UI can mark "me" with the same rule the read boundary uses
  /// (the assignee picker badges the signed-in user's row) instead of a second,
  /// drifting definition of self.
  Set<String> get identityCodes =>
      <String>{currentUserCode, currentStaffCode}
        ..removeWhere((code) => code.isEmpty);

  /// Whether [task] is assigned to the current user. "My Tasks" shows only
  /// tasks assigned to the current user (PRD FR-TK-19) — note this is the
  /// *view* scope and is intentionally narrower than manage-ownership in
  /// `TaskAccess` (which also covers tasks the staff member created).
  ///
  /// Fails closed while the identity is unresolved: "my tasks" for an unknown
  /// user must never widen to everyone else's tasks.
  bool _isMine(Task task) {
    final codes = identityCodes;
    if (codes.isEmpty) return false;
    return codes.contains(task.assigneeCode);
  }

  /// How "created by me" is decided, given who is signed in. Held here so the
  /// "By Me" scope, the read boundary and `TaskAccess` all share one rule (and
  /// one swap point) instead of each comparing creator fields themselves.
  TaskCreatorMatcher get creatorMatcher => TaskCreatorMatcher(
        identityCodes: identityCodes,
        displayName: currentUserName,
      );

  /// Whether [task] was created by the current user — backs the staff "By Me"
  /// scope. Fails closed while the identity is unresolved, as [_isMine] does.
  ///
  /// "Unresolved" deliberately still means *no identity code*, even though the
  /// creator is matched by name: a display name alone is a weak signal (a
  /// namesake matches it), so it grants authorship only once the session has
  /// actually resolved who this user is. Same gate as `TaskAccess`.
  bool _isByMe(Task task) {
    if (identityCodes.isEmpty) return false;
    return creatorMatcher.matches(task);
  }

  /// Distinct assignees referenced by a task this persona can see — offline-safe
  /// options for the assignee filter dropdown. Built from [visibleTasks] so a
  /// staff persona's dropdown never lists colleagues off their own tasks.
  List<TaskAssigneeRef> get assigneeOptions {
    final byCode = <String, String>{};
    for (final task in visibleTasks) {
      if (task.assigneeCode.isNotEmpty) {
        byCode[task.assigneeCode] = task.assigneeName;
      }
    }
    final options = byCode.entries
        .map((e) => (code: e.key, name: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return options;
  }

  /// Distinct creators referenced by a task this persona can see — offline-safe
  /// options for the "Created By" filter dropdown (see [assigneeOptions]).
  List<TaskAssigneeRef> get createdByOptions {
    final byCode = <String, String>{};
    for (final task in visibleTasks) {
      if (task.createdBy.isNotEmpty) {
        byCode[task.createdBy] =
            task.createdByName.isNotEmpty ? task.createdByName : task.createdBy;
      }
    }
    final options = byCode.entries
        .map((e) => (code: e.key, name: e.value))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return options;
  }

  Task? taskByCode(String code) {
    for (final task in tasks) {
      if (task.code == code) return task;
    }
    return null;
  }

  TasksState copyWith({
    List<Task>? tasks,
    bool? isLoading,
    bool? isSaving,
    TaskScope? scope,
    String? searchQuery,
    Set<String>? assigneeFilter,
    Set<String>? createdByFilter,
    Set<TaskPriority>? priorityFilter,
    Set<TaskStatus>? statusFilter,
    DateTime? Function()? dateFrom,
    DateTime? Function()? dateTo,
    bool? overdueOnly,
    String? currentUserCode,
    String? currentUserName,
    String? currentStaffCode,
    String? Function()? errorMessage,
    String? schoolTimeZone,
    TaskPersona? persona,
    Map<String, List<TaskAttachment>>? attachmentsByTask,
    Set<String>? attachmentsUnavailable,
  }) {
    final resolvedError =
        errorMessage != null ? errorMessage() : this.errorMessage;
    final bumpedNonce = errorMessage != null && resolvedError != null
        ? errorNonce + 1
        : errorNonce;
    return TasksState(
      tasks: tasks ?? this.tasks,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      scope: scope ?? this.scope,
      searchQuery: searchQuery ?? this.searchQuery,
      assigneeFilter: assigneeFilter ?? this.assigneeFilter,
      createdByFilter: createdByFilter ?? this.createdByFilter,
      priorityFilter: priorityFilter ?? this.priorityFilter,
      statusFilter: statusFilter ?? this.statusFilter,
      dateFrom: dateFrom != null ? dateFrom() : this.dateFrom,
      dateTo: dateTo != null ? dateTo() : this.dateTo,
      overdueOnly: overdueOnly ?? this.overdueOnly,
      currentUserCode: currentUserCode ?? this.currentUserCode,
      currentUserName: currentUserName ?? this.currentUserName,
      currentStaffCode: currentStaffCode ?? this.currentStaffCode,
      errorMessage: resolvedError,
      errorNonce: bumpedNonce,
      schoolTimeZone: schoolTimeZone ?? this.schoolTimeZone,
      persona: persona ?? this.persona,
      attachmentsByTask: attachmentsByTask ?? this.attachmentsByTask,
      attachmentsUnavailable:
          attachmentsUnavailable ?? this.attachmentsUnavailable,
    );
  }

  @override
  List<Object?> get props => [
        tasks,
        isLoading,
        isSaving,
        scope,
        searchQuery,
        assigneeFilter,
        createdByFilter,
        priorityFilter,
        statusFilter,
        dateFrom,
        dateTo,
        overdueOnly,
        currentUserCode,
        currentUserName,
        currentStaffCode,
        errorMessage,
        errorNonce,
        schoolTimeZone,
        persona,
        attachmentsByTask,
        attachmentsUnavailable,
      ];
}
