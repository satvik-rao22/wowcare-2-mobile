import 'package:wowcare/redesign/features/attendance/models/clock_time.dart';
import 'package:wowcare/redesign/features/attendance/models/day_selection.dart';

/// How M04 writes a date, a time and a span.
///
/// Duration is arithmetic on the two times the row already carries. The API
/// sums nothing, so "Here 1h 39m so far" is worked out here.
abstract final class AttendanceFormats {
  static const List<String> _weekdays = <String>[
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const List<String> _months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  /// "Thu 20 Aug".
  static String weekdayDate(DateTime day) =>
      '${_weekdays[day.weekday - 1]} ${shortDate(day)}';

  /// "20 Aug".
  static String shortDate(DateTime day) =>
      '${day.day} ${_months[day.month - 1]}';

  /// "Today · Thu 20 Aug", "Yesterday · Wed 19 Aug", or "Mon 17 Aug".
  static String dayLabel(DateTime day, DateTime today) {
    final label = weekdayDate(day);
    return switch (daysBetween(day, today)) {
      0 => 'Today · $label',
      1 => 'Yesterday · $label',
      _ => label,
    };
  }

  /// "1 Aug – 20 Aug".
  static String rangeLabel(DateRange range) =>
      '${shortDate(range.from)} – ${shortDate(range.to)}';

  /// Whole days from [day] back to [today], ignoring the time of day.
  static int daysBetween(DateTime day, DateTime today) =>
      _midnight(today).difference(_midnight(day)).inDays;

  static bool isSameDay(DateTime a, DateTime b) => _midnight(a) == _midnight(b);

  static DateTime _midnight(DateTime at) => DateTime(at.year, at.month, at.day);

  /// "7h 5m", "49m". The short span a row and a card write.
  static String span(int minutes) {
    final safe = minutes < 0 ? 0 : minutes;
    final hours = safe ~/ 60;
    final rest = safe % 60;
    if (hours == 0) return '${rest}m';
    return '${hours}h ${rest}m';
  }

  /// The span between two times on the same day.
  static String between(ClockTime from, ClockTime to) =>
      span(from.minutesUntil(to));

  /// "128 Hrs 40 Mins", the long form 4f writes on a range total.
  static String longSpan(int hours, int minutes) => '$hours Hrs $minutes Mins';

  /// A list of first names, as a sentence: "Amara", "Amara and Sam",
  /// "Amara, Sam and Theo".
  static String names(List<String> names) {
    if (names.isEmpty) return '';
    if (names.length == 1) return names.first;
    final head = names.sublist(0, names.length - 1).join(', ');
    return '$head and ${names.last}';
  }
}
