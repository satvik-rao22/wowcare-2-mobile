import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/utils/core_utils.dart';
import 'package:wowcare/core/utils/debouncer.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/view_model/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_access.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_option_picker.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';
import 'package:wowcare/presentation/features/tasks/view/task_detail_screen.dart';
import 'package:wowcare/presentation/features/tasks/view/task_form_screen.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_card.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_edit_scope_sheet.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_filter_sheet.dart';
import 'package:wowcare/shared/common/widgets/access_restricted_view.dart';
import 'package:wowcare/shared/common/app/cubits/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';

/// How the Tasks module lays out its content. Mobile Kanban uses status tabs
/// over a single column (PRD FR-TK-14) rather than the desktop's 3 columns.
enum _TasksViewMode { kanban, list }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  static const String routeName = '/dashboard/tasks';

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TasksViewMode _viewMode = _TasksViewMode.kanban;
  TaskStatus _kanbanStatus = TaskStatus.toDo;
  final TextEditingController _searchController = TextEditingController();

  /// Debounces the search field so a burst of keystrokes triggers a single
  /// re-filter (and board rebuild) once typing settles (PRD FR-TK-20).
  final Debouncer _searchDebouncer = Debouncer();

  @override
  void dispose() {
    _searchDebouncer.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleCubit>();
    // The route guard bounces an unauthorised entry, but it only runs on
    // navigation — permissions can also land (or be revoked on a school
    // switch) while the board is already open.
    if (!TaskAccess.canAccessModule(roles)) {
      return const GlobalScaffold(
        hasBackButton: false,
        showCustomNavigationBar: true,
        body: AccessRestrictedView(
          message: 'You do not have access to tasks for your selected school.',
        ),
      );
    }
    return GlobalScaffold(
      hasBackButton: false,
      showCustomNavigationBar: true,
      floatingActionButton: _addFab(context, roles),
      // RoleCubit resolves the persona asynchronously (it starts on its
      // 'admin' default and settles once /users/details answers). The route
      // applies whatever persona is known when the board opens, so re-apply it
      // whenever the role actually changes — otherwise a staff session that
      // opened Tasks before its role landed would keep the admin read scope
      // (PRD §5.2). applyPersona clears the previous persona's board, so refetch.
      body: BlocListener<RoleCubit, RoleState>(
        listenWhen: (prev, curr) => prev.role != curr.role,
        listener: (context, roleState) {
          final cubit = context.read<TasksCubit>();
          cubit.applyPersona(roleState.role);
          cubit.load(silent: true);
        },
        child: BlocConsumer<TasksCubit, TasksState>(
          // Surface failures (e.g. a status/priority change the backend
          // rejects) instead of silently leaving the card unchanged. Keyed off
          // errorNonce (not the message text) so two failures in a row with
          // identical text (e.g. repeated offline retries) still each show their
          // own toast instead of the second one being silently dropped.
          listenWhen: (prev, curr) =>
              curr.errorMessage != null && curr.errorNonce != prev.errorNonce,
          listener: (context, state) => CoreUtils.showTopSnackBar(
            context: context,
            message: state.errorMessage!,
            isError: true,
          ),
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _controlsRow(context, state, roles),
                  const SizedBox(height: 10),
                  _toolbar(context, state),
                  const SizedBox(height: 10),
                  if (state.isLoading)
                    const Expanded(
                      child: Center(child: PrimaryCircularLoader()),
                    )
                  else if (_viewMode == _TasksViewMode.kanban)
                    Expanded(child: _kanbanView(context, state, roles))
                  else
                    Expanded(child: _listView(context, state, roles)),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // --------------------------------------------------------------- fab

  /// Bottom-right FAB for creating a task, matching the Events screen's add
  /// button (same size, radius and gradient). Returns null when the persona
  /// can't create tasks, so no button renders.
  Widget? _addFab(BuildContext context, RoleCubit roles) {
    if (!TaskAccess.canCreateTasks(roles)) return null;

    return Container(
      width: 64,
      height: 64,
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: AppColors.buildPrimaryGradient(),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryColor.withValues(alpha: 0.30),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => _openCreateForm(context),
          child: const Center(
            child: Icon(Icons.add, color: Colors.white, size: 32),
          ),
        ),
      ),
    );
  }

  /// Scope toggle (PRD FR-TK-19) + Kanban/List view switcher. Staff personas
  /// switch between "For me" (assigned to them) and "By Me" (created by them);
  /// admins switch between "My Tasks" and "All Tasks".
  Widget _controlsRow(BuildContext context, TasksState state, RoleCubit roles) {
    final cubit = context.read<TasksCubit>();
    // Only admins may see the whole school (PRD §5.2); a staff persona's second
    // tab is "By Me" (tasks they created), never everyone's tasks.
    final scopedToOwn = !TaskAccess.canViewAllTasks(roles);
    final leftLabel = scopedToOwn ? 'For me' : 'My Tasks';
    final rightLabel = scopedToOwn ? 'By Me' : 'All Tasks';
    final rightScope = scopedToOwn ? TaskScope.byMe : TaskScope.all;
    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                _scopeTab(
                  label: leftLabel,
                  selected: state.scope == TaskScope.mine,
                  onTap: () => cubit.setScope(TaskScope.mine),
                ),
                _scopeTab(
                  label: rightLabel,
                  selected: state.scope == rightScope,
                  onTap: () => cubit.setScope(rightScope),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        _viewSwitcher(),
      ],
    );
  }

  Widget _scopeTab({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: selected ? AppColors.buildPrimaryGradient() : null,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : AppColors.primaryColor,
            ),
          ),
        ),
      ),
    );
  }

  Widget _viewSwitcher() {
    Widget option(_TasksViewMode mode, IconData icon, String tooltip) {
      final selected = _viewMode == mode;
      return Tooltip(
        message: tooltip,
        child: GestureDetector(
          onTap: () => setState(() => _viewMode = mode),
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              gradient: selected ? AppColors.buildPrimaryGradient() : null,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(
              icon,
              size: 16,
              color: selected ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          option(_TasksViewMode.kanban, Icons.view_kanban_outlined, 'Kanban'),
          option(_TasksViewMode.list, Icons.view_agenda_outlined, 'List'),
        ],
      ),
    );
  }

  /// Search field + filter button (PRD FR-TK-20/22).
  Widget _toolbar(BuildContext context, TasksState state) {
    final cubit = context.read<TasksCubit>();
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 38,
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  _searchDebouncer.run(() => cubit.setSearchQuery(value)),
              decoration: InputDecoration(
                hintText: 'Search tasks…',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                prefixIcon:
                    const Icon(Icons.search, size: 18, color: Colors.grey),
                suffixIcon: state.searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close,
                            size: 16, color: Colors.grey),
                        onPressed: () {
                          // Clear immediately and drop any pending debounce so
                          // a late keystroke can't re-populate the query.
                          _searchDebouncer.cancel();
                          _searchController.clear();
                          cubit.setSearchQuery('');
                        },
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.zero,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.themeColor),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        _filterButton(context, state),
      ],
    );
  }

  Widget _filterButton(BuildContext context, TasksState state) {
    final count = state.filterCount;
    final hasFilters = count > 0;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Material(
          color: hasFilters
              ? AppColors.themeColor.withValues(alpha: 0.12)
              : Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => showTaskFilterSheet(context),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color:
                      hasFilters ? AppColors.themeColor : Colors.grey.shade300,
                ),
              ),
              child:
                  const Icon(Icons.tune, size: 18, color: AppColors.themeColor),
            ),
          ),
        ),
        if (hasFilters)
          Positioned(
            top: -4,
            right: -4,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: AppColors.themeColor,
                shape: BoxShape.circle,
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------- kanban view

  Widget _kanbanView(BuildContext context, TasksState state, RoleCubit roles) {
    // One filter pass shared by the tab counts and the visible column, instead
    // of re-running the full filter for each (3 counts + the column).
    final filtered = state.filteredTasks;
    final counts = <TaskStatus, int>{
      for (final status in TaskStatus.values)
        status: filtered.where((t) => t.status == status).length,
    };
    final columnTasks = TasksState.orderColumn(filtered, _kanbanStatus);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusTabs(counts),
        const SizedBox(height: 10),
        Expanded(
          child: _statusColumn(context, state, roles, _kanbanStatus, columnTasks),
        ),
      ],
    );
  }

  Widget _statusTabs(Map<TaskStatus, int> counts) {
    Widget tab(TaskStatus status) {
      final selected = _kanbanStatus == status;
      final color = TaskUiUtils.statusColor(status);
      final count = counts[status] ?? 0;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _kanbanStatus = status),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            margin: const EdgeInsets.symmetric(horizontal: 2),
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.16)
                  : Colors.white,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: selected
                    ? color.withValues(alpha: 0.5)
                    : Colors.grey.shade300,
              ),
            ),
            child: Column(
              children: [
                Text(
                  status.label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? color : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        for (final status in TaskStatus.values) tab(status),
      ],
    );
  }

  Widget _statusColumn(
    BuildContext context,
    TasksState state,
    RoleCubit roles,
    TaskStatus status,
    List<Task> tasks,
  ) {
    if (tasks.isEmpty) {
      return _emptyState('No ${status.label.toLowerCase()} tasks');
    }
    return RefreshIndicator(
      color: AppColors.themeColor,
      onRefresh: () => context.read<TasksCubit>().load(silent: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _buildCard(context, state, roles, tasks[index]),
      ),
    );
  }

  // --------------------------------------------------------- list view

  Widget _listView(BuildContext context, TasksState state, RoleCubit roles) {
    // Completed tasks are surfaced via the status filter rather than a
    // dedicated section, so the list simply shows all filtered tasks. One
    // filter pass, reused for both the active and completed orderings.
    final tasks = TasksState.listFrom(state.filteredTasks);
    if (tasks.isEmpty) {
      return _emptyState('No tasks match the current filters');
    }
    return RefreshIndicator(
      color: AppColors.themeColor,
      onRefresh: () => context.read<TasksCubit>().load(silent: true),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 90),
        itemCount: tasks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) =>
            _buildCard(context, state, roles, tasks[index]),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context,
    TasksState state,
    RoleCubit roles,
    Task task,
  ) {
    final canManage = TaskAccess.canManageTask(
      roles: roles,
      task: task,
      userCode: state.currentUserCode,
      staffCode: state.currentStaffCode,
      userName: state.currentUserName,
    );
    return TaskCard(
      // Stable identity so Flutter reuses elements when the overdue-first
      // ordering reorders cards, instead of mismatching them to stale data.
      key: ValueKey(task.code),
      task: task,
      schoolTimeZone: state.schoolTimeZone,
      onTap: () => _openDetail(context, task),
      onStatusTap:
          canManage ? () => _showStatusPicker(context, task) : null,
      onMore: canManage ? () => _showCardActions(context, task) : null,
    );
  }

  // ------------------------------------------------- inline status/priority

  Future<void> _showStatusPicker(BuildContext context, Task task) async {
    final cubit = context.read<TasksCubit>();
    final picked = await showTaskOptionPicker<TaskStatus>(
      context: context,
      title: 'Move task to',
      options: TaskStatus.values,
      current: task.status,
      colorOf: TaskUiUtils.statusColor,
      iconOf: TaskUiUtils.statusIcon,
      labelOf: (s) => s.label,
    );
    if (picked != null) cubit.changeStatus(task.code, picked);
  }

  Future<void> _showCardActions(BuildContext context, Task task) async {
    final cubit = context.read<TasksCubit>();
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.open_in_new,
                  color: AppColors.themeColor),
              title: const Text('View details'),
              onTap: () => Navigator.pop(sheetContext, 'view'),
            ),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: AppColors.themeColor),
              title: const Text('Edit'),
              onTap: () => Navigator.pop(sheetContext, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline,
                  color: AppColors.errorColor),
              title: const Text('Delete'),
              onTap: () => Navigator.pop(sheetContext, 'delete'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (!context.mounted) return;
    switch (action) {
      case 'view':
        _openDetail(context, task);
      case 'edit':
        await _openEditForm(context, task);
      case 'delete':
        await _confirmDelete(context, cubit, task);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TasksCubit cubit,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete task?'),
        content: Text('Do you want to delete this task - "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) await cubit.delete(task.code);
  }

  // ------------------------------------------------------------ shared

  Widget _emptyState(String message) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.checklist_rtl_outlined,
                    size: 44, color: Colors.grey[400]),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context, Task task) {
    context.push(
      TaskDetailScreen.routeName,
      extra: <String, dynamic>{'taskCode': task.code},
    );
  }

  /// Create only — an *edit* must go through [_openEditForm] so a recurring task
  /// is never edited without first asking which occurrences it applies to.
  void _openCreateForm(BuildContext context) {
    context.push(
      TaskFormScreen.routeName,
      extra: const <String, dynamic>{},
    );
  }

  /// Editing a recurring task asks which occurrences to modify first, so the
  /// form opens already knowing how far the save will reach.
  Future<void> _openEditForm(BuildContext context, Task task) async {
    final cubit = context.read<TasksCubit>();
    final choice = await askTaskEditScope(
      context: context,
      cubit: cubit,
      task: task,
    );
    if (choice.cancelled || !context.mounted) return;
    await context.push(
      TaskFormScreen.routeName,
      extra: <String, dynamic>{
        'taskCode': task.code,
        'editScope': choice.scope,
      },
    );
  }
}
