import 'package:wowcare/domain/features/tasks/entities/task.dart';
import 'package:wowcare/domain/features/tasks/entities/task_series.dart';

/// Bridges series-level schedule data onto the flat assignment [Task].
///
/// The Tasks API's assignment card carries the occurrence date and the due
/// instant, but NOT the start time-of-day or the recurrence rule — those live
/// only on the owning series (bridged by `taskCode`). These helpers recover
/// them so the detail view and edit form show the real start time and cadence
/// instead of the entity's placeholder defaults.
abstract final class TaskScheduleUtils {
  /// Normalizes a series time (`HH:mm:ss` or `HH:mm`) to the `HH:mm` the entity
  /// and UI expect. Returns null when the value is absent or malformed, so
  /// callers can fall back to whatever they already had.
  static String? hhmm(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  /// Maps an RRULE weekday abbreviation (`MO`) to the full name (`MONDAY`) the
  /// form and [Task.startDay] use. Null for an unrecognized token.
  static String? weekdayFromAbbr(String abbr) {
    const map = <String, String>{
      'MO': 'MONDAY',
      'TU': 'TUESDAY',
      'WE': 'WEDNESDAY',
      'TH': 'THURSDAY',
      'FR': 'FRIDAY',
      'SA': 'SATURDAY',
      'SU': 'SUNDAY',
    };
    return map[abbr.trim().toUpperCase()];
  }

  /// Maps a series recurrence to the `startDay` shape the entity/UI read: a
  /// weekday name for weekly, the day-of-month string for monthly, null for
  /// daily or non-recurring.
  static String? seriesStartDay(TaskSeries series) {
    switch (series.recurrencePattern) {
      case TaskRecurrence.weekly:
        if (series.recurrenceByDay.isEmpty) return null;
        return weekdayFromAbbr(series.recurrenceByDay.first);
      case TaskRecurrence.monthly:
        return series.recurrenceByMonthday?.toString();
      case TaskRecurrence.daily:
      case null:
        return null;
    }
  }

  /// Overlays [series]' recurrence onto a flat assignment [card]. Start/due
  /// date and time are left untouched — they're per-occurrence and already
  /// correct on the card (the assignment payload now carries its own
  /// `startTime`/`dueTime`, §5b); only the recurrence shape (the "Repeats"
  /// row) still lives solely on the series.
  static Task withSeriesSchedule(Task card, TaskSeries series) {
    return card.copyWith(
      recurring: series.recurring,
      recurringPattern: () => series.recurrencePattern,
      recurringEndDate: () => series.recurrenceUntil,
      startDay: () => seriesStartDay(series),
    );
  }
}
