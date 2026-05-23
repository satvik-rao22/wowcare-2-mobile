import 'package:flutter/material.dart';

class ShiftTimeValidators {
  static int toMinutes(TimeOfDay time) => (time.hour * 60) + time.minute;

  static bool isWithinShift(TimeOfDay t, TimeOfDay start, TimeOfDay end) {
    final value = toMinutes(t);
    return value >= toMinutes(start) && value <= toMinutes(end);
  }

  static String? validateShiftRange({
    required TimeOfDay? start,
    required TimeOfDay? end,
  }) {
    if (start == null || end == null) return null;
    if (toMinutes(start) >= toMinutes(end)) {
      return 'Shift end time must be after shift start time';
    }
    return null;
  }

  static String? validateBreakRange({
    required TimeOfDay? breakStart,
    required TimeOfDay? breakEnd,
    required TimeOfDay? shiftStart,
    required TimeOfDay? shiftEnd,
  }) {
    final hasOneBreak = (breakStart == null) != (breakEnd == null);
    if (hasOneBreak) {
      return 'Please select both break start and break end time';
    }

    if (breakStart == null || breakEnd == null) return null;
    if (shiftStart == null || shiftEnd == null) return null;

    if (!isWithinShift(breakStart, shiftStart, shiftEnd) ||
        !isWithinShift(breakEnd, shiftStart, shiftEnd)) {
      return 'Break time must be within the selected shift range';
    }

    if (toMinutes(breakStart) >= toMinutes(breakEnd)) {
      return 'Break end time must be after break start time';
    }

    // Break duration cannot exceed shift duration.
    final breakDuration = toMinutes(breakEnd) - toMinutes(breakStart);
    final shiftDuration = toMinutes(shiftEnd) - toMinutes(shiftStart);
    if (breakDuration > shiftDuration) {
      return 'Break duration cannot exceed shift duration';
    }

    return null;
  }
}

