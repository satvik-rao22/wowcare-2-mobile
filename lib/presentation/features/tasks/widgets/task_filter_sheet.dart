import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/cubit/tasks_cubit.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';

/// Bottom-drawer filter panel (mobile counterpart of the web design's filter
/// dropdowns): assignee, priority, status, due-date range and an overdue-only
/// toggle (PRD FR-TK-21/22). Changes apply live through [TasksCubit].
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

class _TaskFilterSheet extends StatelessWidget {
  const _TaskFilterSheet();

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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),
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
                            child: const Text(
                              'Clear all',
                              style: TextStyle(fontSize: 12.5),
                            ),
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
                                selected:
                                    state.statusFilter.contains(status),
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
                                selected:
                                    state.priorityFilter.contains(priority),
                                onTap: () =>
                                    cubit.togglePriorityFilter(priority),
                              ),
                          ],
                        ),
                        if (state.assigneeOptions.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          _sectionLabel('Assignee'),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              for (final assignee in state.assigneeOptions)
                                _chip(
                                  label: assignee.name,
                                  color: TaskUiUtils.accent,
                                  selected: state.assigneeFilter
                                      .contains(assignee.code),
                                  onTap: () => cubit
                                      .toggleAssigneeFilter(assignee.code),
                                ),
                            ],
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
                                  from: date,
                                  to: state.dateTo,
                                ),
                                onCleared: () => cubit.setDateRange(
                                  from: null,
                                  to: state.dateTo,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _dateField(
                                context: context,
                                label: 'To',
                                value: state.dateTo,
                                onPicked: (date) => cubit.setDateRange(
                                  from: state.dateFrom,
                                  to: date,
                                ),
                                onCleared: () => cubit.setDateRange(
                                  from: state.dateFrom,
                                  to: null,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        _OverdueToggle(
                          value: state.overdueOnly,
                          onChanged: cubit.setOverdueOnly,
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
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
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            state.filterCount > 0
                                ? 'Apply (${state.filterCount})'
                                : 'Done',
                            style: const TextStyle(
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
            ),
          ),
        );
      },
    );
  }

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
  }) {
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
                  child: Icon(Icons.close, size: 15, color: Colors.grey[600]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OverdueToggle extends StatelessWidget {
  const _OverdueToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              size: 17, color: TaskUiUtils.overdueColor),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Overdue only',
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: TaskUiUtils.overdueColor,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
