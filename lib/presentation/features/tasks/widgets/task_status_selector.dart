import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';

/// Segmented status control — the task detail screen's primary action.
///
/// Status is the one field a task's owner changes over and over, so on the
/// detail screen it is a control rather than a badge: all three states are
/// visible at once and moving between them is a single tap, with no picker
/// sheet in between.
///
/// [onChanged] null makes it display-only, for a persona that may read the task
/// but not manage it.
class TaskStatusSelector extends StatelessWidget {
  const TaskStatusSelector({
    required this.status,
    this.onChanged,
    super.key,
  });

  final TaskStatus status;
  final ValueChanged<TaskStatus>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final option in TaskStatus.values) ...[
          if (option != TaskStatus.values.first) const SizedBox(width: 6),
          Expanded(child: _segment(option)),
        ],
      ],
    );
  }

  Widget _segment(TaskStatus option) {
    final selected = option == status;
    final color = TaskUiUtils.statusColor(option);
    final enabled = onChanged != null;
    final content = AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      decoration: BoxDecoration(
        color: selected ? color : AppPalette.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? color : AppPalette.border,
          width: selected ? 1.5 : 1,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            selected ? Icons.check : TaskUiUtils.statusIcon(option),
            size: 17,
            color: selected ? AppPalette.onBrand : color,
          ),
          const SizedBox(height: 4),
          Text(
            option.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: selected ? AppPalette.onBrand : AppPalette.textPrimary,
            ),
          ),
        ],
      ),
    );

    return KeyedSubtree(
      key: ValueKey('task-status-segment-${option.name}'),
      child: Semantics(
        button: enabled,
        selected: selected,
        label: option.label,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            // Already on this status, or read-only: nothing to do.
            onTap: enabled && !selected ? () => onChanged!(option) : null,
            borderRadius: BorderRadius.circular(10),
            child: content,
          ),
        ),
      ),
    );
  }
}
