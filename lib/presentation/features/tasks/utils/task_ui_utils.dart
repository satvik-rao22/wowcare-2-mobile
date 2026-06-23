import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';

/// Visual mapping for task statuses and priorities, adapted from the Figma
/// Make tasks design (To Do = amber, In Progress = blue, Completed = green;
/// task accent = purple) to the app's existing palette.
class TaskUiUtils {
  TaskUiUtils._();

  /// Purple accent shared with the calendar's task chips (PRD FR-SC-11).
  static const Color accent = Color(0xFF9C6BF7);
  static const Color overdueColor = Color(0xFFD32F2F);

  static Color statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.toDo:
        return const Color(0xFFF9A825); // amber
      case TaskStatus.inProgress:
        return const Color(0xFF4A90D9); // blue
      case TaskStatus.completed:
        return const Color(0xFF4CAF50); // green
    }
  }

  static Color statusBackground(TaskStatus status) =>
      statusColor(status).withValues(alpha: 0.10);

  static IconData statusIcon(TaskStatus status) {
    switch (status) {
      case TaskStatus.toDo:
        return Icons.radio_button_unchecked;
      case TaskStatus.inProgress:
        return Icons.timelapse_outlined;
      case TaskStatus.completed:
        return Icons.check_circle_outline;
    }
  }

  static Color priorityColor(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return const Color(0xFF388E3C); // green
      case TaskPriority.medium:
        return const Color(0xFFF9A825); // amber
      case TaskPriority.high:
        return const Color(0xFFEF6C00); // orange (distinct from overdue red)
    }
  }

  static IconData priorityIcon(TaskPriority priority) {
    switch (priority) {
      case TaskPriority.low:
        return Icons.arrow_downward;
      case TaskPriority.medium:
        return Icons.drag_handle;
      case TaskPriority.high:
        return Icons.priority_high;
    }
  }

  /// Formats a `HH:mm` 24-hour string as `h:mm AM/PM`. Returns the raw value
  /// when it doesn't parse.
  static String formatTime(String hhmm) {
    final parts = hhmm.split(':');
    if (parts.length != 2) return hhmm;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return hhmm;
    final dt = DateTime(2000, 1, 1, hour, minute);
    return DateFormat('h:mm a').format(dt);
  }

  /// "Jun 19, 4:00 PM" style label for a due date + time.
  static String dueLabel(Task task) {
    final date = DateFormat('MMM d').format(task.dueDate);
    final time = formatTime(task.dueTime);
    return time.isEmpty ? date : '$date • $time';
  }

  /// "Every Monday", "Monthly (1st–25th)", "Daily" style recurrence summary.
  static String recurrenceLabel(Task task) {
    if (!task.recurring || task.recurringPattern == null) return 'Does not repeat';
    switch (task.recurringPattern!) {
      case TaskRecurrence.daily:
        return 'Repeats daily';
      case TaskRecurrence.weekly:
        final day = (task.startDay ?? '').isEmpty
            ? ''
            : ' • ${_titleCase(task.startDay!)}';
        return 'Repeats weekly$day';
      case TaskRecurrence.monthly:
        final day = (task.startDay ?? '').isEmpty ? '' : ' • day ${task.startDay}';
        return 'Repeats monthly$day';
    }
  }

  /// "2.5 hrs" / "1 hr" effort label, empty when no effort recorded.
  static String effortLabel(double effort) {
    if (effort <= 0) return '';
    final formatted =
        effort == effort.roundToDouble() ? effort.toStringAsFixed(0) : effort.toString();
    return '$formatted ${effort == 1 ? 'hr' : 'hrs'}';
  }

  static String _titleCase(String value) {
    if (value.isEmpty) return value;
    final lower = value.toLowerCase();
    return '${lower[0].toUpperCase()}${lower.substring(1)}';
  }
}
