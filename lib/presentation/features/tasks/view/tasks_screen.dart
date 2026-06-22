import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/cubit/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_access.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';
import 'package:wowcare/presentation/features/tasks/view/task_detail_screen.dart';
import 'package:wowcare/presentation/features/tasks/view/task_form_screen.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_card.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_filter_sheet.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';
import 'package:wowcare/shared/common/widgets/gradient_add_button.dart';
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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roles = context.watch<RoleCubit>();
    return GlobalScaffold(
      hasBackButton: false,
      showCustomNavigationBar: true,
      body: BlocBuilder<TasksCubit, TasksState>(
        builder: (context, state) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _header(context, roles),
                const SizedBox(height: 10),
                _controlsRow(context, state),
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
    );
  }

  // ------------------------------------------------------------ header

  Widget _header(BuildContext context, RoleCubit roles) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tasks',
              style: TextStyle(
                color: AppColors.primaryColor,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              'Manage and track tasks for your team',
              style: TextStyle(fontSize: 11.5, color: Colors.grey[600]),
            ),
          ],
        ),
        if (TaskAccess.canCreateTasks(roles))
          GradientAddButton(onTap: () => _openForm(context)),
      ],
    );
  }

  /// My/All scope toggle (PRD FR-TK-19) + Kanban/List view switcher.
  Widget _controlsRow(BuildContext context, TasksState state) {
    final cubit = context.read<TasksCubit>();
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
                  label: 'My Tasks',
                  selected: state.showMineOnly,
                  onTap: () => cubit.setShowMineOnly(true),
                ),
                _scopeTab(
                  label: 'All Tasks',
                  selected: !state.showMineOnly,
                  onTap: () => cubit.setShowMineOnly(false),
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
              onChanged: cubit.setSearchQuery,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _statusTabs(state),
        const SizedBox(height: 10),
        Expanded(child: _statusColumn(context, state, roles, _kanbanStatus)),
      ],
    );
  }

  Widget _statusTabs(TasksState state) {
    Widget tab(TaskStatus status) {
      final selected = _kanbanStatus == status;
      final color = TaskUiUtils.statusColor(status);
      final count = state.countWithStatus(status);
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
  ) {
    final tasks = state.orderedTasksWithStatus(status);
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
    // dedicated section, so the list simply shows all filtered tasks.
    final tasks = state.listTasksOrdered;
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
    );
    return TaskCard(
      task: task,
      onTap: () => _openDetail(context, task),
      onStatusTap:
          canManage ? () => _showStatusPicker(context, task) : null,
      onPriorityTap:
          canManage ? () => _showPriorityPicker(context, task) : null,
      onMore: canManage ? () => _showCardActions(context, task) : null,
    );
  }

  // ------------------------------------------------- inline status/priority

  Future<void> _showStatusPicker(BuildContext context, Task task) async {
    final cubit = context.read<TasksCubit>();
    await _showOptionsSheet<TaskStatus>(
      context: context,
      title: 'Move task to',
      options: TaskStatus.values,
      current: task.status,
      colorOf: TaskUiUtils.statusColor,
      iconOf: TaskUiUtils.statusIcon,
      labelOf: (s) => s.label,
    ).then((picked) {
      if (picked != null) cubit.changeStatus(task.code, picked);
    });
  }

  Future<void> _showPriorityPicker(BuildContext context, Task task) async {
    final cubit = context.read<TasksCubit>();
    await _showOptionsSheet<TaskPriority>(
      context: context,
      title: 'Set priority',
      options: TaskPriority.values,
      current: task.priority,
      colorOf: TaskUiUtils.priorityColor,
      iconOf: TaskUiUtils.priorityIcon,
      labelOf: (p) => p.label,
    ).then((picked) {
      if (picked != null) cubit.changePriority(task.code, picked);
    });
  }

  Future<T?> _showOptionsSheet<T>({
    required BuildContext context,
    required String title,
    required List<T> options,
    required T current,
    required Color Function(T) colorOf,
    required IconData Function(T) iconOf,
    required String Function(T) labelOf,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
            ),
            for (final option in options)
              ListTile(
                leading: Icon(iconOf(option), color: colorOf(option)),
                title: Text(
                  labelOf(option),
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: option == current
                    ? const Icon(Icons.check, color: AppColors.themeColor)
                    : null,
                onTap: () => Navigator.pop(sheetContext, option),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
        _openForm(context, task: task);
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

  void _openForm(BuildContext context, {Task? task}) {
    context.push(
      TaskFormScreen.routeName,
      extra: <String, dynamic>{if (task != null) 'taskCode': task.code},
    );
  }
}
