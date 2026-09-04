import 'package:wowcare/domain/features/events/entities/recurrence_rule.dart';

/// Product policy for the recurrence "Until" date.
///
/// The events API requires a bounded UNTIL (COUNT is rejected — no
/// infinite series), so every frequency gets:
/// - a **default** that covers the common school intent without creating
///   an absurd occurrence count (daily routines are term-scoped, weekly
///   clubs run a semester, monthly patterns run a school year, yearly
///   events span a few anniversaries), and
/// - a **maximum** that caps server-side occurrence materialization
///   (daily × 1 year ≈ 365 occurrences is already the heaviest allowed).
///
/// | Frequency | Default        | Maximum   |
/// |-----------|----------------|-----------|
/// | Daily     | +1 month       | +1 year   |
/// | Weekly    | +3 months      | +2 years  |
/// | Monthly   | +1 year        | +3 years  |
/// | Yearly    | +3 years       | +5 years  |
class RecurrenceEndPolicy {
  RecurrenceEndPolicy._();

  /// Pre-filled "Until" when recurrence is enabled or the unit changes.
  static DateTime defaultEnd(RecurrenceFrequency frequency, DateTime start) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return DateTime(start.year, start.month + 1, start.day);
      case RecurrenceFrequency.weekly:
        return DateTime(start.year, start.month + 3, start.day);
      case RecurrenceFrequency.monthly:
        return DateTime(start.year + 1, start.month, start.day);
      case RecurrenceFrequency.yearly:
        return DateTime(start.year + 3, start.month, start.day);
    }
  }

  /// Latest selectable "Until" for the date picker.
  static DateTime maxEnd(RecurrenceFrequency frequency, DateTime start) {
    switch (frequency) {
      case RecurrenceFrequency.daily:
        return DateTime(start.year + 1, start.month, start.day);
      case RecurrenceFrequency.weekly:
        return DateTime(start.year + 2, start.month, start.day);
      case RecurrenceFrequency.monthly:
        return DateTime(start.year + 3, start.month, start.day);
      case RecurrenceFrequency.yearly:
        return DateTime(start.year + 5, start.month, start.day);
    }
  }

  /// [end] forced into the valid window for [frequency] anchored at
  /// [start]: null or before the start falls back to the default, beyond
  /// the maximum clamps to it.
  static DateTime clamp(
    DateTime? end,
    RecurrenceFrequency frequency,
    DateTime start,
  ) {
    if (end == null || end.isBefore(start)) {
      return defaultEnd(frequency, start);
    }
    final max = maxEnd(frequency, start);
    return end.isAfter(max) ? max : end;
  }
}
