import '../../core/utils/av2_date_formatter.dart';

/// The selected reporting period — either a whole calendar month or a custom
/// date interval. Drives the hero card's range chip label.
class Av2Period {
  const Av2Period({
    required this.start,
    required this.end,
    required this.isWholeMonth,
  });

  final DateTime start;
  final DateTime end;
  final bool isWholeMonth;

  /// Whole calendar month containing [anyDayInMonth].
  factory Av2Period.month(DateTime anyDayInMonth) {
    final start = DateTime(anyDayInMonth.year, anyDayInMonth.month, 1);
    final end = DateTime(anyDayInMonth.year, anyDayInMonth.month + 1, 0);
    return Av2Period(start: start, end: end, isWholeMonth: true);
  }

  /// Arbitrary [start]..[end] interval.
  factory Av2Period.custom(DateTime start, DateTime end) =>
      Av2Period(start: start, end: end, isWholeMonth: false);

  /// "Jun 2026" for a month, "Jun 1 – Jun 12, 2026" for a custom range.
  String get label => isWholeMonth
      ? Av2DateFormatter.monthYear(start)
      : Av2DateFormatter.range(start, end);

  Av2Period copyWith({DateTime? start, DateTime? end, bool? isWholeMonth}) =>
      Av2Period(
        start: start ?? this.start,
        end: end ?? this.end,
        isWholeMonth: isWholeMonth ?? this.isWholeMonth,
      );
}
