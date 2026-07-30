import 'package:flutter/material.dart' show TimeOfDay;

/// Pure validation helpers for the task form, kept out of the widget so the
/// rules (no negative datetime ranges for either a one-off or a recurring
/// task, a mandatory "Until" end date that can't precede the start, a
/// well-formed effort value) are unit-testable on their own.
abstract final class TaskFormValidation {
  /// Combines a calendar [date] with a [time] into a single moment.
  static DateTime combine(DateTime date, TimeOfDay time) =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

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

  /// True when the recurrence "Until" end date is on or after the [start] date
  /// — a series can't end before it begins. Compared date-only.
  static bool isEndOnOrAfterStart({
    required DateTime start,
    required DateTime until,
  }) =>
      !_dateOnly(until).isBefore(_dateOnly(start));

  /// True when the estimated-effort text is acceptable: blank (treated as 0) or
  /// a non-negative number. Guards against a stray `1.2.3` or a negative value.
  static bool isEffortValid(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return true;
    final parsed = double.tryParse(value);
    return parsed != null && parsed >= 0;
  }

  /// Whether the form may be submitted. Title and at least one assignee are
  /// always required, and the start→due window must be non-negative — for a
  /// recurring task this is its **derived** window (the caller resolves the
  /// concrete dates from the recurrence fields first). A recurring task
  /// additionally requires an "Until" [recurrenceEnd] that is on or after the
  /// start (the API mandates the RRULE's `UNTIL`, BR-REC).
  static bool canSubmit({
    required String title,
    required bool hasAssignee,
    required bool recurring,
    required DateTime startDate,
    required TimeOfDay startTime,
    required DateTime dueDate,
    required TimeOfDay dueTime,
    DateTime? recurrenceEnd,
  }) {
    if (title.trim().isEmpty || !hasAssignee) return false;
    if (recurring) {
      if (recurrenceEnd == null) return false;
      if (!isEndOnOrAfterStart(start: startDate, until: recurrenceEnd)) {
        return false;
      }
    }
    return isNonNegativeRange(
      startDate: startDate,
      startTime: startTime,
      dueDate: dueDate,
      dueTime: dueTime,
    );
  }
}
