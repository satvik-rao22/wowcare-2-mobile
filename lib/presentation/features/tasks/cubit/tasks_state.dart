part of 'tasks_cubit.dart';

class TasksState extends Equatable {
  const TasksState({
    required this.tasks,
    required this.isLoading,
    required this.isSaving,
    required this.showMineOnly,
    required this.searchQuery,
    required this.assigneeFilter,
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
        showMineOnly = false,
        searchQuery = '',
        assigneeFilter = const <String>{},
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

  /// "My Tasks" scope (PRD FR-TK-19): only tasks assigned to the current
  /// user. Defaults true for staff personas, false for admins.
  final bool showMineOnly;

  /// Free-text filter on title/description (PRD FR-TK-20, fires per keystroke).
  final String searchQuery;

  /// Empty sets mean "show all".
  final Set<String> assigneeFilter;
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
      if (showMineOnly && !_isMine(task)) return false;
      if (assigneeFilter.isNotEmpty &&
          !assigneeFilter.contains(task.assigneeCode)) {
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

  /// Whether [task] is assigned to or created by the current user.
  bool _isMine(Task task) {
    final codes = <String>{currentUserCode, currentStaffCode}
      ..removeWhere((code) => code.isEmpty);
    if (codes.isEmpty) return true;
    return codes.contains(task.assigneeCode) || codes.contains(task.createdBy);
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
    bool? showMineOnly,
    String? searchQuery,
    Set<String>? assigneeFilter,
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
      showMineOnly: showMineOnly ?? this.showMineOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      assigneeFilter: assigneeFilter ?? this.assigneeFilter,
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
        showMineOnly,
        searchQuery,
        assigneeFilter,
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
