import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';

/// Read-only priority readout for the task detail screen.
///
/// Priority is set from the edit form, never inline, so this deliberately
/// exposes no gesture affordance. It reads as a level rather than a label: three
/// bars, filled to the priority's rank, so Low/Medium/High is legible at a
/// glance and is visibly *quieter* than the status control beside it — status is
/// the primary action, this is context.
class TaskPriorityMeter extends StatelessWidget {
  const TaskPriorityMeter({required this.priority, super.key});

  final TaskPriority priority;

  /// Rank within [TaskPriority], 1-based — how many bars are filled.
  int get _level => TaskPriority.values.indexOf(priority) + 1;

  @override
  Widget build(BuildContext context) {
    final color = TaskUiUtils.priorityColor(priority);
    return Semantics(
      label: 'Priority',
      value: priority.label,
      readOnly: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(TaskUiUtils.priorityIcon(priority), size: 16, color: color),
            const SizedBox(width: 8),
            const Text(
              'Priority',
              style: TextStyle(fontSize: 12, color: AppPalette.textSecondary),
            ),
            const Spacer(),
            _bars(color),
            const SizedBox(width: 8),
            Text(
              priority.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bars(Color color) {
    return Row(
      key: const ValueKey('task-priority-bars'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var rank = 1; rank <= TaskPriority.values.length; rank++) ...[
          if (rank > 1) const SizedBox(width: 3),
          DecoratedBox(
            decoration: BoxDecoration(
              color: rank <= _level ? color : color.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(2),
            ),
            // Ascending heights read as a level meter rather than a progress
            // bar, so a low priority still looks deliberate, not "unfinished".
            child: SizedBox(width: 4, height: 6.0 + rank * 3),
          ),
        ],
      ],
    );
  }
}
