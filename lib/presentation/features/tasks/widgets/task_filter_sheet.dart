import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/cubit/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';

/// Bottom-drawer filter panel for tasks. Short, fixed dimensions (status,
/// priority, overdue) stay inline; the open-ended Assignee dimension drills
/// into a second searchable stage *within the same sheet* so it scales to
/// large lists without a wall of chips. Options come from the already-loaded
/// tasks (offline-safe, no extra network calls) and changes apply live
/// through [TasksCubit] (PRD FR-TK-21/22).
Future<void> showTaskFilterSheet(BuildContext context) {
  final cubit = context.read<TasksCubit>();
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => BlocProvider.value(
      value: cubit,
      child: const _TaskFilterSheet(),
    ),
  );
}

/// Which second-stage list (if any) the sheet is currently showing.
enum _FilterStage { root, assignee }

class _TaskFilterSheet extends StatefulWidget {
  const _TaskFilterSheet();

  @override
  State<_TaskFilterSheet> createState() => _TaskFilterSheetState();
}

class _TaskFilterSheetState extends State<_TaskFilterSheet> {
  _FilterStage _stage = _FilterStage.root;

  void _open(_FilterStage stage) => setState(() => _stage = stage);
  void _back() => setState(() => _stage = _FilterStage.root);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TasksCubit, TasksState>(
      builder: (context, state) {
        final cubit = context.read<TasksCubit>();
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.85,
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                transitionBuilder: (child, animation) => SlideTransition(
                  position: Tween<Offset>(
                    begin: Offset(
                        child.key == const ValueKey(_FilterStage.root)
                            ? -0.15
                            : 0.15,
                        0),
                    end: Offset.zero,
                  ).animate(animation),
                  child: FadeTransition(opacity: animation, child: child),
                ),
                child: _stage == _FilterStage.root
                    ? _root(context, state, cubit)
                    : _assigneeStage(context, state, cubit),
              ),
            ),
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------------- root

  Widget _root(BuildContext context, TasksState state, TasksCubit cubit) {
    return Column(
      key: const ValueKey(_FilterStage.root),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _grabber(),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filters',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              if (state.hasActiveFilters)
                TextButton(
                  onPressed: cubit.clearAllFilters,
                  child: const Text('Clear all',
                      style: TextStyle(fontSize: 12.5)),
                ),
            ],
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            children: [
              _sectionLabel('Status'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final status in TaskStatus.values)
                    _chip(
                      label: status.label,
                      color: TaskUiUtils.statusColor(status),
                      selected: state.statusFilter.contains(status),
                      // Completed contradicts "Overdue only" — a completed
                      // task is never overdue — so disable it while that
                      // toggle is on.
                      disabled: status == TaskStatus.completed &&
                          state.overdueOnly,
                      onTap: () => cubit.toggleStatusFilter(status),
                    ),
                ],
              ),
              const SizedBox(height: 14),
              _sectionLabel('Priority'),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final priority in TaskPriority.values)
                    _chip(
                      label: priority.label,
                      color: TaskUiUtils.priorityColor(priority),
                      selected: state.priorityFilter.contains(priority),
                      onTap: () => cubit.togglePriorityFilter(priority),
                    ),
                ],
              ),
              if (state.assigneeOptions.isNotEmpty) ...[
                const SizedBox(height: 14),
                _sectionLabel('Assignee'),
                _navRow(
                  icon: Icons.person_outline,
                  color: TaskUiUtils.accent,
                  label: 'Assignees',
                  selectedCount: state.assigneeFilter.length,
                  onTap: () => _open(_FilterStage.assignee),
                ),
              ],
              const SizedBox(height: 14),
              _sectionLabel('Due Date Range'),
              Row(
                children: [
                  Expanded(
                    child: _dateField(
                      context: context,
                      label: 'From',
                      value: state.dateFrom,
                      onPicked: (date) => cubit.setDateRange(
                          from: date, to: state.dateTo),
                      onCleared: () => cubit.setDateRange(
                          from: null, to: state.dateTo),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _dateField(
                      context: context,
                      label: 'To',
                      value: state.dateTo,
                      onPicked: (date) => cubit.setDateRange(
                          from: state.dateFrom, to: date),
                      onCleared: () => cubit.setDateRange(
                          from: state.dateFrom, to: null),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _OverdueToggle(
                value: state.overdueOnly,
                // Mirror of the Completed guard above: a completed task is
                // never overdue, so disable this toggle while Completed is
                // an active status filter.
                enabled: !state.statusFilter.contains(TaskStatus.completed),
                onChanged: cubit.setOverdueOnly,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: _primaryButton(
            label: state.filterCount > 0
                ? 'Apply (${state.filterCount})'
                : 'Done',
            onTap: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------- assignee stage

  Widget _assigneeStage(
    BuildContext context,
    TasksState state,
    TasksCubit cubit,
  ) {
    return _CategoryFilterList(
      key: const ValueKey(_FilterStage.assignee),
      title: 'Assignees',
      options: [
        for (final assignee in state.assigneeOptions)
          (code: assignee.code, name: assignee.name),
      ],
      selected: state.assigneeFilter,
      accent: TaskUiUtils.accent,
      onToggle: cubit.toggleAssigneeFilter,
      onBack: _back,
    );
  }

  // --------------------------------------------------------------- shared

  Widget _grabber() => Center(
        child: Container(
          width: 38,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      );

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget _chip({
    required String label,
    required Color color,
    required bool selected,
    required VoidCallback onTap,
    bool disabled = false,
  }) {
    if (disabled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade400,
          ),
        ),
      );
    }
    return Material(
      color: selected ? color : color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white : color,
            ),
          ),
        ),
      ),
    );
  }

  /// Forward-arrow row that drills into a second-stage list (mirrors the
  /// assignee picker used inside the task form).
  Widget _navRow({
    required IconData icon,
    required Color color,
    required String label,
    required int selectedCount,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  selectedCount == 0
                      ? 'Any ${label.toLowerCase()}'
                      : '$selectedCount selected',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color:
                        selectedCount == 0 ? Colors.grey[600] : Colors.black87,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[500]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dateField({
    required BuildContext context,
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime> onPicked,
    required VoidCallback onCleared,
  }) {
    return Material(
      color: Colors.grey[100],
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(DateTime.now().year - 2),
            lastDate: DateTime(DateTime.now().year + 3),
          );
          if (picked != null) {
            onPicked(DateTime(picked.year, picked.month, picked.day));
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined,
                  size: 15, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  value == null
                      ? label
                      : DateFormat('MMM d, yyyy').format(value),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: value == null ? Colors.grey[600] : Colors.black87,
                  ),
                ),
              ),
              if (value != null)
                GestureDetector(
                  onTap: onCleared,
                  child:
                      Icon(Icons.close, size: 15, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppColors.buildPrimaryGradient(),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          onPressed: onTap,
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _OverdueToggle extends StatelessWidget {
  const _OverdueToggle({
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final accent =
        enabled ? TaskUiUtils.overdueColor : Colors.grey.shade400;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: 17, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Overdue only',
              style: TextStyle(
                fontSize: 13,
                color: enabled ? Colors.black87 : Colors.grey.shade400,
              ),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: TaskUiUtils.overdueColor,
            onChanged: enabled ? onChanged : null,
          ),
        ],
      ),
    );
  }
}

/// Lightweight (code, name) option used by the second-stage list.
typedef _FilterOption = ({String code, String name});

/// Second-stage searchable, scrollable multi-select list shown inside the
/// filter sheet. Selections toggle live through the cubit; "Done" returns to
/// the root stage.
class _CategoryFilterList extends StatefulWidget {
  const _CategoryFilterList({
    required this.title,
    required this.options,
    required this.selected,
    required this.accent,
    required this.onToggle,
    required this.onBack,
    super.key,
  });

  final String title;
  final List<_FilterOption> options;
  final Set<String> selected;
  final Color accent;
  final ValueChanged<String> onToggle;
  final VoidCallback onBack;

  @override
  State<_CategoryFilterList> createState() => _CategoryFilterListState();
}

class _CategoryFilterListState extends State<_CategoryFilterList> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.options
        .where((o) =>
            _query.isEmpty ||
            o.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, size: 20),
                color: AppColors.primaryColor,
                onPressed: widget.onBack,
              ),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              if (widget.selected.isNotEmpty)
                Text(
                  '${widget.selected.length} selected',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              const SizedBox(width: 8),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search ${widget.title.toLowerCase()}…',
                hintStyle: TextStyle(fontSize: 13, color: Colors.grey[500]),
                prefixIcon: const Icon(Icons.search, size: 19),
                isDense: true,
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'No matches',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final option = filtered[index];
                      final checked = widget.selected.contains(option.code);
                      return CheckboxListTile(
                        dense: true,
                        value: checked,
                        activeColor: widget.accent,
                        controlAffinity: ListTileControlAffinity.trailing,
                        title: Text(
                          option.name.isNotEmpty ? option.name : option.code,
                          style: const TextStyle(fontSize: 13.5),
                        ),
                        onChanged: (_) => widget.onToggle(option.code),
                      );
                    },
                  ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.buildPrimaryGradient(),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: widget.onBack,
                  child: const Text(
                    'Done',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
