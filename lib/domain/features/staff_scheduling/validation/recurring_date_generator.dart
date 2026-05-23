class RecurringDateGenerator {
  /// Generates all dates from [startDate]..[untilDate] (inclusive) matching
  /// ISO weekday codes in [repeatDayCodes] (1=Mon..7=Sun).
  static List<DateTime> generate({
    required DateTime startDate,
    required DateTime untilDate,
    required List<int> repeatDayCodes,
  }) {
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(untilDate.year, untilDate.month, untilDate.day);
    if (repeatDayCodes.isEmpty) return [start];
    if (end.isBefore(start)) return [];

    final codes = repeatDayCodes.toSet();
    final out = <DateTime>[];
    var cursor = start;
    while (!cursor.isAfter(end)) {
      if (codes.contains(cursor.weekday)) {
        out.add(cursor);
      }
      cursor = cursor.add(const Duration(days: 1));
    }
    return out;
  }
}

