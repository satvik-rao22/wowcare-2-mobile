import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_elevation.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_decoration.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';
import 'package:wowcare/core/theme/app_haptics.dart';

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
      // The chosen status is a key in its own status colour: a solid face
      // over the key glow. The other two are quiet card-faced peers.
      decoration: selected
          ? SkeuDecoration(
              color: color,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color, width: 1.5),
              boxShadow: AppElevation.keyGlow(color),
            )
          : AppSurfaces.card(radius: 10),
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
            onTap: enabled && !selected
                ? () {
                    AppHaptics.select();
                    onChanged!(option);
                  }
                : null,
            borderRadius: BorderRadius.circular(10),
            child: content,
          ),
        ),
      ),
    );
  }
}
