import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_ui_utils.dart';
import 'package:wowcare/presentation/features/tasks/widgets/task_badges.dart';

/// Mobile task card used by both the Kanban column and List view. Surfaces
/// the fields the PRD calls out (FR-TK-17): assignee, title, description,
/// due date, priority, status and an overdue indicator.
class TaskCard extends StatelessWidget {
  const TaskCard({
    required this.task,
    required this.onTap,
    this.onStatusTap,
    this.onPriorityTap,
    this.onMore,
    super.key,
  });

  final Task task;
  final VoidCallback onTap;

  /// Inline status/priority editing (PRD FR-TK-16) — null hides the affordance
  /// for users without permission.
  final VoidCallback? onStatusTap;
  final VoidCallback? onPriorityTap;
  final VoidCallback? onMore;

  @override
  Widget build(BuildContext context) {
    final overdue = task.isOverdue;
    final accent = overdue ? TaskUiUtils.overdueColor : TaskUiUtils.accent;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accent.withValues(alpha: 0.18)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
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
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          task.assigneeName.isEmpty
                              ? 'Unassigned'
                              : task.assigneeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  if (onMore != null)
                    GestureDetector(
                      onTap: onMore,
                      child: Icon(Icons.more_vert,
                          size: 18, color: Colors.grey[500]),
                    ),
                ],
              ),
              if (task.description.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  task.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined,
                      size: 13, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    TaskUiUtils.dueLabel(task),
                    style: TextStyle(
                      fontSize: 11.5,
                      color: overdue ? TaskUiUtils.overdueColor : Colors.grey[700],
                      fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  if (task.recurring) ...[
                    const SizedBox(width: 8),
                    Icon(Icons.repeat, size: 13, color: Colors.grey[600]),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  if (overdue) const TaskOverdueBadge(),
                  TaskPriorityBadge(
                    priority: task.priority,
                    onTap: onPriorityTap,
                  ),
                  TaskStatusBadge(status: task.status, onTap: onStatusTap),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
