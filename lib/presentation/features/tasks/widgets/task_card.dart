import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_badges.dart';

/// Mobile task card used by both the Kanban column and List view. Surfaces
/// the fields the PRD calls out (FR-TK-17): assignee, title, due date,
/// priority, status and an overdue indicator. Description is intentionally
/// omitted from the card to keep it compact (shown on the detail screen).
class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.schoolTimeZone,
    required this.onTap,
    this.onStatusTap,
    this.onMore,
    super.key,
  });

  final Task task;

  /// School's IANA timezone — converts [task]'s UTC due date/time into the
  /// local wall-clock label shown on the card.
  final String schoolTimeZone;
  final VoidCallback onTap;

  /// Inline status editing (PRD FR-TK-16) — null hides the affordance for users
  /// without permission. Priority has no inline equivalent by design; it is
  /// shown read-only and changed from the edit form.
  final VoidCallback? onStatusTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    // Completed tasks read as a muted "archive" entry (the green status badge
    // already labels them "Completed"); overdue tasks get the red accent.
    final completed = task.status == TaskStatus.completed;
    final accent = completed
        ? AppPalette.textMuted
        : (overdue ? TaskUiUtils.overdueColor : TaskUiUtils.accent);
    final card = Material(
      color: AppPalette.surfaceCard,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
            boxShadow: completed
                ? null
                : [
                    BoxShadow(
                      color: AppPalette.shadowAmbient.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TaskAssigneeAvatar(
                    name: task.assigneeName,
                    code: task.assigneeCode,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppPalette.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.assigneeName.isEmpty
                              ? 'Unassigned'
                              : task.assigneeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppPalette.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  if (onMore != null)
                    GestureDetector(
                      onTap: onMore,
                      child: const Icon(Icons.more_vert,
                          size: 18, color: AppPalette.textMuted),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.calendar_today_outlined,
                      size: 13, color: AppPalette.textSecondary),
                  const SizedBox(width: 4),
                  Text(
                    TaskUiUtils.dueLabelInZone(task, schoolTimeZone),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: overdue
                          ? TaskUiUtils.overdueColor
                          : AppPalette.textSecondary,
                      fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (task.recurring) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.repeat,
                        size: 13, color: AppPalette.textSecondary),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (overdue) const TaskOverdueBadge(),
                  TaskPriorityBadge(priority: task.priority),
                  TaskStatusBadge(status: task.status, onTap: onStatusTap),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    return completed ? Opacity(opacity: 0.85, child: card) : card;
  }
}
