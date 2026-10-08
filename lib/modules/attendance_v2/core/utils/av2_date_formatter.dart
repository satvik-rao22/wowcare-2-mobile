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

  /// Time used in session tiles and regularization rows: "08:03 AM",
  /// "02:14 PM". Same `hh:mm a` shape as the rest of the app — a lone "a"/"p"
  /// read as a typo next to every other screen's AM/PM.
  static String compactTime(DateTime d) => _time12.format(d);

  /// "Jun 1 – Jun 30, 2026" for a range chip / header.
  static String range(DateTime from, DateTime to) {
    final sameYear = from.year == to.year;
    final left = _monthDay.format(from);
    final right = DateFormat('MMM d, yyyy').format(to);
    return sameYear ? '$left – $right' : '${DateFormat('MMM d, yyyy').format(from)} – $right';
  }
}
