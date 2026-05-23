import 'package:flutter/material.dart';
import '../../staff/entities/staff_profile.dart';
import 'shift_time_validators.dart';

class AvailabilityValidator {
  const AvailabilityValidator();

  bool isWithinAvailabilityForDate({
    required StaffProfile profile,
    required DateTime date,
    required TimeOfDay shiftStart,
    required TimeOfDay shiftEnd,
    TimeOfDay? breakStart,
    TimeOfDay? breakEnd,
  }) {
    final weekdayName = _weekdayName(date.weekday);

    final work = profile.workSchedules
        .where((w) => w.dayOfWeek.trim().toLowerCase() == weekdayName)
        .toList(growable: false);

    // No work schedule for that day => not available.
    if (work.isEmpty) return false;

    bool withinAnyWorkWindow = false;
    for (final w in work) {
      final ws = TimeOfDay(hour: w.workStartTime.hour, minute: w.workStartTime.minute);
      final we = TimeOfDay(hour: w.workEndTime.hour, minute: w.workEndTime.minute);
      if (ShiftTimeValidators.toMinutes(shiftStart) >= ShiftTimeValidators.toMinutes(ws) &&
          ShiftTimeValidators.toMinutes(shiftEnd) <= ShiftTimeValidators.toMinutes(we)) {
        withinAnyWorkWindow = true;
        break;
      }
    }
    if (!withinAnyWorkWindow) return false;

    if (breakStart == null || breakEnd == null) return true;

    // If break schedules are provided, ensure break is within at least one break window.
    final breaks = profile.breakSchedules
        .where((b) => b.dayOfWeek.trim().toLowerCase() == weekdayName)
        .toList(growable: false);

    if (breaks.isEmpty) {
      // If staff has no break schedule configured, treat break as part of shift;
      // availability still holds.
      return true;
    }

    for (final b in breaks) {
      final bs = TimeOfDay(hour: b.breakStartTime.hour, minute: b.breakStartTime.minute);
      final be = TimeOfDay(hour: b.breakEndTime.hour, minute: b.breakEndTime.minute);
      if (ShiftTimeValidators.toMinutes(breakStart) >= ShiftTimeValidators.toMinutes(bs) &&
          ShiftTimeValidators.toMinutes(breakEnd) <= ShiftTimeValidators.toMinutes(be)) {
        return true;
      }
    }
    return false;
  }

  String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'monday';
      case DateTime.tuesday:
        return 'tuesday';
      case DateTime.wednesday:
        return 'wednesday';
      case DateTime.thursday:
        return 'thursday';
      case DateTime.friday:
        return 'friday';
      case DateTime.saturday:
        return 'saturday';
      case DateTime.sunday:
        return 'sunday';
      default:
        return '';
    }
  }
}

