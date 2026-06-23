part of 'tasks_cubit.dart';

/// Which slice of tasks the list/board shows.
///
/// Admins toggle between [all] ("All Tasks") and [mine] ("My Tasks"). Staff
/// instead toggle between [mine] ("For me" — assigned to them) and [byMe]
/// ("By Me" — created by them). See [TasksState.filteredTasks].
enum TaskScope { all, mine, byMe }

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
        errorMessage = null;

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

  /// Tasks passing the scope / assignee / priority / status / date / overdue
  /// filters and the search query.
  List<Task> get filteredTasks {
    final now = DateTime.now();
    final query = searchQuery.trim().toLowerCase();
    return tasks.where((task) {
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
      if (query.isNotEmpty &&
          !task.title.toLowerCase().contains(query) &&
          !task.description.toLowerCase().contains(query)) {
        return false;
      }
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
  List<Task> orderedTasksWithStatus(TaskStatus status) {
    final list = tasksWithStatus(status);
    if (status == TaskStatus.completed) {
      return list..sort((a, b) => b.dueAt.compareTo(a.dueAt));
    }
    return _overdueFirst(list);
  }

  /// Non-completed filtered tasks, overdue first then the rest — backs the
  /// list view's active list.
  List<Task> get activeTasksOrdered => _overdueFirst(
        filteredTasks.where((t) => t.status != TaskStatus.completed).toList(),
      );

  /// Completed filtered tasks, most recently due first.
  List<Task> get completedTasksOrdered =>
      filteredTasks.where((t) => t.status == TaskStatus.completed).toList()
        ..sort((a, b) => b.dueAt.compareTo(a.dueAt));

  /// All filtered tasks for the list view: active first (overdue first),
  /// then completed (most recently due last). The status filter narrows this
  /// when the user wants only completed (or any single status).
  List<Task> get listTasksOrdered =>
      [...activeTasksOrdered, ...completedTasksOrdered];

  /// Orders [source] with overdue tasks first (by due moment), then the
  /// remaining tasks (also by due moment).
  List<Task> _overdueFirst(List<Task> source) {
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

  /// Whether [task] is assigned to the current user. "My Tasks" shows only
  /// tasks assigned to the current user (PRD FR-TK-19) — note this is the
  /// *view* scope and is intentionally narrower than manage-ownership in
  /// `TaskAccess` (which also covers tasks the staff member created).
  /// Permissive while the user identity hasn't resolved yet.
  bool _isMine(Task task) {
    final codes = <String>{currentUserCode, currentStaffCode}
      ..removeWhere((code) => code.isEmpty);
    if (codes.isEmpty) return true;
    return codes.contains(task.assigneeCode);
  }

  /// Whether [task] was created by the current user — backs the staff "By Me"
  /// scope. Permissive while the user identity hasn't resolved yet.
  bool _isByMe(Task task) {
    final codes = <String>{currentUserCode, currentStaffCode}
      ..removeWhere((code) => code.isEmpty);
    if (codes.isEmpty) return true;
    return codes.contains(task.createdBy);
  }

  /// Distinct assignees referenced by any task — offline-safe options for the
  /// assignee filter dropdown.
  List<TaskAssigneeRef> get assigneeOptions {
    final byCode = <String, String>{};
    for (final task in tasks) {
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

  /// Distinct creators referenced by any task — offline-safe options for the
  /// "Created By" filter dropdown.
  List<TaskAssigneeRef> get createdByOptions {
    final byCode = <String, String>{};
    for (final task in tasks) {
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
  }) {
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
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
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
      ];
}
