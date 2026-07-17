import 'package:flutter/material.dart' show TimeOfDay;

/// Pure validation helpers for the task form, kept out of the widget so the
/// rules (no negative datetime ranges; which fields are mandatory for a
/// one-off vs a recurring task) are unit-testable on their own.
abstract final class TaskFormValidation {
  /// Combines a calendar [date] with a [time] into a single moment.
  static DateTime combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  /// True when the due moment is not before the start moment — i.e. the range
  /// is non-negative. Start 16th 00:00 with due 15th 23:59 is invalid; an
  /// identical start/due (zero-length) is allowed.
  static bool isNonNegativeRange({
    required DateTime startDate,
    required TimeOfDay startTime,
    required DateTime dueDate,
    required TimeOfDay dueTime,
  }) {
    final start = combine(startDate, startTime);
    final due = combine(dueDate, dueTime);
    return !due.isBefore(start);
  }

  /// Whether the form may be submitted. Title and at least one assignee are
  /// always required. A **one-off** task additionally needs a non-negative
  /// start→due window; a **recurring** task derives its window from the
  /// recurrence fields (which always carry a value), so the window check does
  /// not apply.
  static bool canSubmit({
    required String title,
    required bool hasAssignee,
    required bool recurring,
    required DateTime startDate,
    required TimeOfDay startTime,
    required DateTime dueDate,
    required TimeOfDay dueTime,
  }) {
    if (title.trim().isEmpty || !hasAssignee) return false;
    if (recurring) return true;
    return isNonNegativeRange(
      startDate: startDate,
      startTime: startTime,
      dueDate: dueDate,
      dueTime: dueTime,
    );
  }
}
