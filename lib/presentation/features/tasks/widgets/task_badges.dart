import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';

/// Pill badge showing a task's status, optionally tappable for inline editing
/// (PRD FR-TK-16).
class TaskStatusBadge extends StatelessWidget {
  const TaskStatusBadge({required this.status, this.onTap, super.key});

  final TaskStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = TaskUiUtils.statusColor(status);
    return _Pill(
      color: color,
      icon: TaskUiUtils.statusIcon(status),
      label: status.label,
      onTap: onTap,
    );
  }
}

/// Pill badge showing a task's priority. Always read-only: priority is set from
/// the edit form, never inline, so this exposes no tap affordance at all (the
/// caret [_Pill] adds for tappable pills would misadvertise it as a control).
class TaskPriorityBadge extends StatelessWidget {
  const TaskPriorityBadge({required this.priority, super.key});

  final TaskPriority priority;

  @override
  Widget build(BuildContext context) {
    final color = TaskUiUtils.priorityColor(priority);
    return _Pill(
      color: color,
      icon: TaskUiUtils.priorityIcon(priority),
      label: priority.label,
    );
  }
}

/// Red "Overdue" badge (PRD FR-TK-18).
class TaskOverdueBadge extends StatelessWidget {
  const TaskOverdueBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return _Pill(
      color: TaskUiUtils.overdueColor,
      icon: Icons.error_outline,
      label: 'Overdue',
    );
  }
}

/// Circular initials avatar for an assignee, coloured from the shared profile
/// palette so the same person reads consistently across the app.
class TaskAssigneeAvatar extends StatelessWidget {
  const TaskAssigneeAvatar({
    required this.name,
    required this.code,
    this.size = 34,
    super.key,
  });

  final String name;
  final String code;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = AppColors.profileAvatarColors;
    final seed = (code.isNotEmpty ? code : name);
    final color = palette[seed.hashCode.abs() % palette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.25),
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials(name),
        style: TextStyle(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }

  static String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.color,
    required this.icon,
    required this.label,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 2),
            Icon(Icons.expand_more, size: 13, color: color),
          ],
        ],
      ),
    );
    if (onTap == null) return pill;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: pill,
      ),
    );
  }
}
