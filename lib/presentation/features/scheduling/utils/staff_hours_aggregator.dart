import 'package:wowcare/domain/features/scheduling/entities/staff_shift_hours_entry.dart';

/// Sums [StaffShiftHoursEntry] rows per staff for a single calendar day.
class StaffHoursAggregator {
  const StaffHoursAggregator._();

  static Map<String, StaffHoursTotals> totalsByStaffForDay({
    required Iterable<StaffShiftHoursEntry> entries,
    required DateTime day,
  }) {
    final map = <String, StaffHoursTotals>{};
    for (final entry in entries) {
      if (!_sameCalendarDay(entry.shiftDate, day)) continue;
      final code = entry.staffCode.trim();
      if (code.isEmpty) continue;

      final prev = map[code] ?? StaffHoursTotals.zero;
      map[code] = StaffHoursTotals(
        availableHours: prev.availableHours + entry.availableHours,
        scheduledHours: prev.scheduledHours + entry.scheduledHours,
        unscheduledHours: prev.unscheduledHours + entry.unscheduledHours,
      );
    }
    return map;
  }

  static StaffHoursTotals sumForStaffOnDay({
    required Iterable<StaffShiftHoursEntry> entries,
    required String staffCode,
    required DateTime day,
  }) {
    final code = staffCode.trim();
    if (code.isEmpty) return StaffHoursTotals.zero;

    var available = 0.0;
    var scheduled = 0.0;
    var unscheduled = 0.0;
    for (final entry in entries) {
      if (entry.staffCode.trim() != code) continue;
      if (!_sameCalendarDay(entry.shiftDate, day)) continue;
      available += entry.availableHours;
      scheduled += entry.scheduledHours;
      unscheduled += entry.unscheduledHours;
    }
    return StaffHoursTotals(
      availableHours: available,
      scheduledHours: scheduled,
      unscheduledHours: unscheduled,
    );
  }

  static bool _sameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
