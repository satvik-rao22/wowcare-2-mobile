import 'package:intl/intl.dart';
import 'package:wowcare/domain/features/events/entities/event.dart';

/// Human-readable copy for [RecurrenceRule]s, matching the web app's
/// Teams-style grammar ("Occurs every other week on Mon, Wed until
/// Dec 18, 2026").
class RecurrenceSummary {
  RecurrenceSummary._();

  static const List<String> _nthLabels = [
    '',
    'first',
    'second',
    'third',
    'fourth',
  ];

  /// UI chip order (Sunday-first, like Teams) as [DateTime.weekday] values.
  static const List<int> chipWeekdays = [
    DateTime.sunday,
    DateTime.monday,
    DateTime.tuesday,
    DateTime.wednesday,
    DateTime.thursday,
    DateTime.friday,
    DateTime.saturday,
  ];

  static const Map<int, String> _shortDayNames = {
    DateTime.sunday: 'Sun',
    DateTime.monday: 'Mon',
    DateTime.tuesday: 'Tue',
    DateTime.wednesday: 'Wed',
    DateTime.thursday: 'Thu',
    DateTime.friday: 'Fri',
    DateTime.saturday: 'Sat',
  };

  /// "15th", "1st", "22nd" — ordinal day-of-month label.
  static String dayOfMonthLabel(DateTime date) {
    final day = date.day;
    final String suffix;
    if (day >= 11 && day <= 13) {
      suffix = 'th';
    } else {
      switch (day % 10) {
        case 1:
          suffix = 'st';
        case 2:
          suffix = 'nd';
        case 3:
          suffix = 'rd';
        default:
          suffix = 'th';
      }
    }
    return '$day$suffix';
  }

  /// "third Wednesday" / "last Friday" — ordinal weekday label.
  static String nthWeekdayLabel(DateTime date) {
    final dayName = DateFormat('EEEE').format(date);
    if (RecurrenceRule.isLastWeekdayOfMonth(date)) return 'last $dayName';
    final nth = RecurrenceRule.nthWeekdayOfMonth(date);
    return '${_nthLabels[nth.clamp(1, 4)]} $dayName';
  }

  /// Short label for cards/chips: "Daily", "Every other week",
  /// "Every 3 months".
  static String compact(RecurrenceRule? rule) {
    if (rule == null) return '';
    final unit = rule.frequency.unitLabel;
    if (rule.interval == 1) {
      switch (rule.frequency) {
        case RecurrenceFrequency.daily:
          return 'Daily';
        case RecurrenceFrequency.weekly:
          return 'Weekly';
        case RecurrenceFrequency.monthly:
          return 'Monthly';
        case RecurrenceFrequency.yearly:
          return 'Yearly';
      }
    }
    if (rule.interval == 2) return 'Every other $unit';
    return 'Every ${rule.interval} ${unit}s';
  }

  /// Full sentence for the form's live summary and the detail screen.
  /// [startDate] anchors day-of-month / nth-weekday phrasing; [startTime]
  /// and [endTime] are the `HH:mm` display strings (empty to omit).
  static String describe({
    required RecurrenceRule rule,
    required DateTime startDate,
    String startTime = '',
    String endTime = '',
  }) {
    final unit = rule.frequency.unitLabel;
    final String intervalPhrase;
    if (rule.interval == 1) {
      intervalPhrase = unit;
    } else if (rule.interval == 2) {
      intervalPhrase = 'other $unit';
    } else {
      intervalPhrase = '${rule.interval} ${unit}s';
    }

    var summary = 'Occurs every $intervalPhrase';

    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
      case RecurrenceFrequency.weekly:
        // Weekday list for weekly always; for daily only a strict subset
        // (interval 1) — "every day" needs no "on" clause.
        final days = rule.daysOfWeek;
        final showDays = rule.frequency == RecurrenceFrequency.weekly
            ? days.isNotEmpty
            : rule.interval == 1 && days.isNotEmpty && days.length < 7;
        if (showDays) {
          final names = [
            for (final day in chipWeekdays)
              if (days.contains(day)) _shortDayNames[day]!,
          ];
          summary += ' on ${names.join(', ')}';
        }
      case RecurrenceFrequency.monthly:
        summary += rule.monthlyMode == MonthlyRepeatMode.nthWeekday
            ? ' on the ${nthWeekdayLabel(startDate)}'
            : ' on day ${dayOfMonthLabel(startDate)}';
      case RecurrenceFrequency.yearly:
        summary += rule.yearlyMode == YearlyRepeatMode.nthWeekday
            ? ' on the ${nthWeekdayLabel(startDate)} of '
                '${DateFormat('MMMM').format(startDate)}'
            : ' on ${DateFormat('MMM d').format(startDate)}';
    }

    if (startTime.isNotEmpty) {
      summary += ', $startTime';
      if (endTime.isNotEmpty) summary += ' – $endTime';
    }

    final end = rule.endDate;
    if (end != null) {
      summary += ', until ${DateFormat('MMM d, yyyy').format(end)}';
    }

    return summary;
  }
}
