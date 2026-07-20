import 'package:equatable/equatable.dart';

/// Repeat unit for a recurring event ("Repeat every N day/week/month/year").
enum RecurrenceFrequency {
  daily('DAILY', 'day'),
  weekly('WEEKLY', 'week'),
  monthly('MONTHLY', 'month'),
  yearly('YEARLY', 'year');

  const RecurrenceFrequency(this.value, this.unitLabel);

  /// RRULE FREQ token.
  final String value;

  /// Singular unit for UI copy ("every 3 weeks" pluralizes in the summary).
  final String unitLabel;

  static RecurrenceFrequency? fromValue(String? raw) {
    final normalized = (raw ?? '').trim().toUpperCase();
    for (final frequency in RecurrenceFrequency.values) {
      if (frequency.value == normalized) return frequency;
    }
    return null;
  }
}

/// Monthly repeat anchor: the start date's day number ("day 15 of every
/// month") or its ordinal weekday ("the third Wednesday of every month").
enum MonthlyRepeatMode { dayOfMonth, nthWeekday }

/// Yearly repeat anchor: the start date itself ("September 15 every year")
/// or its ordinal weekday within the month ("the third Wednesday of
/// September").
enum YearlyRepeatMode { date, nthWeekday }

/// Teams/Outlook-style recurrence rule ("Repeat every 2 weeks on Mon, Wed
/// until Dec 18"). Serialized to/from an RFC 5545 RRULE by the data layer;
/// this object also owns the client-side occurrence matching used by the
/// calendar until server-side occurrences are wired.
class RecurrenceRule extends Equatable {
  const RecurrenceRule({
    required this.frequency,
    this.interval = 1,
    this.daysOfWeek = const <int>{},
    this.monthlyMode = MonthlyRepeatMode.dayOfMonth,
    this.yearlyMode = YearlyRepeatMode.date,
    this.endDate,
  });

  final RecurrenceFrequency frequency;

  /// "Repeat every N" (1–99). 1 = every, 2 = every other, N = every N units.
  final int interval;

  /// Selected weekdays as [DateTime.weekday] values (1=Mon … 7=Sun).
  /// Meaningful for [RecurrenceFrequency.weekly] (empty = start date's
  /// weekday) and for daily at interval 1 (empty = every day).
  final Set<int> daysOfWeek;

  final MonthlyRepeatMode monthlyMode;
  final YearlyRepeatMode yearlyMode;

  /// UNTIL boundary (inclusive). The form requires it; kept nullable so a
  /// backend rule without UNTIL degrades to "ongoing" instead of crashing.
  final DateTime? endDate;

  /// Whether an occurrence of a series anchored at [seriesStart] falls on
  /// [day]. Both are compared date-only.
  bool matches(DateTime day, DateTime seriesStart) {
    final target = DateTime(day.year, day.month, day.day);
    final first =
        DateTime(seriesStart.year, seriesStart.month, seriesStart.day);
    if (target.isBefore(first)) return false;
    final end = endDate;
    if (end != null &&
        target.isAfter(DateTime(end.year, end.month, end.day))) {
      return false;
    }

    switch (frequency) {
      case RecurrenceFrequency.daily:
        // Teams offers the weekday subset only at interval 1; a subset
        // means "every day, but only on these days".
        if (interval == 1) {
          return daysOfWeek.isEmpty || daysOfWeek.contains(target.weekday);
        }
        return target.difference(first).inDays % interval == 0;

      case RecurrenceFrequency.weekly:
        final days = daysOfWeek.isEmpty ? {first.weekday} : daysOfWeek;
        if (!days.contains(target.weekday)) return false;
        if (interval == 1) return true;
        // Sunday-based week index so "every 2 weeks" flips at the week
        // boundary exactly like Teams/Outlook, not N*7 days per selected day.
        return _weeksBetween(first, target) % interval == 0;

      case RecurrenceFrequency.monthly:
        final months =
            (target.year - first.year) * 12 + target.month - first.month;
        if (months % interval != 0) return false;
        return monthlyMode == MonthlyRepeatMode.dayOfMonth
            ? target.day == first.day
            : _sameNthWeekday(target, first);

      case RecurrenceFrequency.yearly:
        if ((target.year - first.year) % interval != 0) return false;
        if (target.month != first.month) return false;
        return yearlyMode == YearlyRepeatMode.date
            ? target.day == first.day
            : _sameNthWeekday(target, first);
    }
  }

  /// Weekday set after the series start moved from [oldWeekday] to
  /// [newWeekday]: the start date's weekday follows the date (Thu → Fri
  /// when the event moves a day later), while other manually picked days
  /// are preserved. No-op when the start's weekday wasn't selected.
  static Set<int> shiftStartWeekday(
    Set<int> days,
    int oldWeekday,
    int newWeekday,
  ) {
    if (days.isEmpty ||
        oldWeekday == newWeekday ||
        !days.contains(oldWeekday)) {
      return days;
    }
    return {...days}
      ..remove(oldWeekday)
      ..add(newWeekday);
  }

  /// Ordinal position of [date]'s weekday within its month, 1-based
  /// ("third Wednesday" → 3).
  static int nthWeekdayOfMonth(DateTime date) => (date.day - 1) ~/ 7 + 1;

  /// Whether [date] is the last occurrence of its weekday in its month.
  static bool isLastWeekdayOfMonth(DateTime date) =>
      date.day + 7 > DateTime(date.year, date.month + 1, 0).day;

  static int _weeksBetween(DateTime first, DateTime target) {
    DateTime startOfWeek(DateTime d) =>
        d.subtract(Duration(days: d.weekday % 7)); // Sunday-based
    return startOfWeek(target).difference(startOfWeek(first)).inDays ~/ 7;
  }

  /// Same weekday and same ordinal slot as the series start. A start date
  /// on the month's LAST occurrence of its weekday matches the last
  /// occurrence in the target month (Teams "last Wednesday" semantics),
  /// even when that is the 4th there and the 5th elsewhere.
  static bool _sameNthWeekday(DateTime target, DateTime first) {
    if (target.weekday != first.weekday) return false;
    if (isLastWeekdayOfMonth(first)) return isLastWeekdayOfMonth(target);
    return nthWeekdayOfMonth(target) == nthWeekdayOfMonth(first);
  }

  RecurrenceRule copyWith({
    RecurrenceFrequency? frequency,
    int? interval,
    Set<int>? daysOfWeek,
    MonthlyRepeatMode? monthlyMode,
    YearlyRepeatMode? yearlyMode,
    DateTime? Function()? endDate,
  }) {
    return RecurrenceRule(
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      monthlyMode: monthlyMode ?? this.monthlyMode,
      yearlyMode: yearlyMode ?? this.yearlyMode,
      endDate: endDate != null ? endDate() : this.endDate,
    );
  }

  @override
  List<Object?> get props =>
      [frequency, interval, daysOfWeek, monthlyMode, yearlyMode, endDate];
}
