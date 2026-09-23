import '../../domain/entities/attendance_day.dart';

/// The single segmented filter that replaces the old Summarised/Separate +
/// Show-Absent toggles.
enum Av2DayFilter { all, overtime, absent, requests }

extension Av2DayFilterX on Av2DayFilter {
  String get label {
    switch (this) {
      case Av2DayFilter.all:
        return 'All days';
      case Av2DayFilter.overtime:
        return 'Overtime';
      case Av2DayFilter.absent:
        return 'Absent';
      case Av2DayFilter.requests:
        return 'Requests';
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
      // Not a day filter: the tab renders the regularization list instead.
      case Av2DayFilter.requests:
        return false;
    }
  }

  /// Applies the filter to a list, preserving order.
  List<AttendanceDay> apply(List<AttendanceDay> days) =>
      days.where(matches).toList(growable: false);
}
