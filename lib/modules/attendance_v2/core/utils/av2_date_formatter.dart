import 'package:intl/intl.dart';

/// Date/time formatting helpers for the module. Centralised so formats stay
/// consistent and localisation changes happen in one place.
class Av2DateFormatter {
  const Av2DateFormatter._();

  static final DateFormat _monthDay = DateFormat('MMM d');
  static final DateFormat _weekday = DateFormat('EEEE');
  static final DateFormat _monthYear = DateFormat('MMM yyyy');
  static final DateFormat _time12 = DateFormat('hh:mm a');

  /// "Jun 11"
  static String monthDay(DateTime d) => _monthDay.format(d);

  /// "Thursday"
  static String weekday(DateTime d) => _weekday.format(d);

  /// "Jun 2026"
  static String monthYear(DateTime d) => _monthYear.format(d);

  /// Compact lower-case time used in session tiles: "08:03a", "02:14p".
  static String compactTime(DateTime d) {
    final s = _time12.format(d); // "08:03 AM"
    final parts = s.split(' ');
    if (parts.length != 2) return s;
    final meridiem = parts[1].toLowerCase().startsWith('p') ? 'p' : 'a';
    return '${parts[0]}$meridiem';
  }

  /// "Jun 1 – Jun 30, 2026" for a range chip / header.
  static String range(DateTime from, DateTime to) {
    final sameYear = from.year == to.year;
    final left = _monthDay.format(from);
    final right = DateFormat('MMM d, yyyy').format(to);
    return sameYear ? '$left – $right' : '${DateFormat('MMM d, yyyy').format(from)} – $right';
  }
}
