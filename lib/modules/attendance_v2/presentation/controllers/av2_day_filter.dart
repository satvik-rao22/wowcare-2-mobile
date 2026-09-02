import '../../domain/entities/attendance_day.dart';

/// The single segmented filter. Maps directly to the overview endpoint's
/// `overtimeOnly` / `absentOnly` server filters.
enum Av2DayFilter { all, overtime, absent }

extension Av2DayFilterX on Av2DayFilter {
  String get label {
    switch (this) {
      case Av2DayFilter.all:
        return 'All days';
      case Av2DayFilter.overtime:
        return 'Overtime';
      case Av2DayFilter.absent:
        return 'Absent';
    }
  }

  bool matches(AttendanceDay day) {
    switch (this) {
      case Av2DayFilter.all:
        return true;
      case Av2DayFilter.overtime:
        return !day.isAbsent && day.hasOvertime;
      case Av2DayFilter.absent:
        return day.isAbsent;
    }
  }

  /// Applies the filter to a list, preserving order.
  List<AttendanceDay> apply(List<AttendanceDay> days) =>
      days.where(matches).toList(growable: false);
}
