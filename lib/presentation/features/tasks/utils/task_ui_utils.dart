import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/presentation/features/tasks/utils/task_timezone.dart';

/// Visual mapping for task statuses and priorities, adapted from the Figma
/// Make tasks design (To Do = amber, In Progress = blue, Completed = green;
/// task accent = purple) to the app's existing palette.
class TaskUiUtils {
  TaskUiUtils._();

  /// Purple accent shared with the calendar's task chips (PRD FR-SC-11).
  static const Color accent = AppPalette.dataPurple;
  static const Color overdueColor = AppPalette.statusError;

  static Color statusColor(TaskStatus status) {
    switch (status) {
      case TaskStatus.toDo:
        return AppPalette.statusWarning; // amber
      case TaskStatus.inProgress:
        return AppPalette.statusInfo; // blue
      case TaskStatus.completed:
        return AppPalette.statusSuccess; // green
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
        return AppPalette.statusSuccess; // green
      case TaskPriority.medium:
        return AppPalette.statusWarning; // amber
      case TaskPriority.high:
        return AppPalette.dataOrange; // orange (distinct from overdue red)
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

  /// Formats a [TimeOfDay] as `h:mm a` without needing a [BuildContext].
  static String formatTimeOfDay(TimeOfDay time) {
    final dt = DateTime(2000, 1, 1, time.hour, time.minute);
    return DateFormat('h:mm a').format(dt);
  }

  /// "Jun 19, 4:00 PM" style due label, converted from the wire's UTC
  /// [Task.dueDate]/[Task.dueTime] into [ianaName]'s school-local wall clock
  /// first — the date itself can shift a day depending on the school's offset.
  static String dueLabelInZone(Task task, String ianaName) {
    final local = TaskTimezone.fromUtcWire(
      utcDate: task.dueDate,
      hhmm: task.dueTime,
      ianaName: ianaName,
    );
    final date = DateFormat('MMM d').format(local.$1);
    return '$date • ${formatTimeOfDay(local.$2)}';
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
