import 'package:flutter/material.dart';
import '../entities/staff_shift.dart';
import 'shift_time_validators.dart';
import 'shift_validation_models.dart';

class SchedulingConflictDetector {
  const SchedulingConflictDetector();

  List<ShiftConflict> detect({
    required List<StaffShiftEntity> existing,
    required DateTime date,
    required TimeOfDay start,
    required TimeOfDay end,
    required String classroomCode,
  }) {
    final day = DateTime(date.year, date.month, date.day);
    final conflicts = <ShiftConflict>[];

    for (final shift in existing) {
      final shiftDate = DateTime.tryParse(shift.shiftDate);
      if (shiftDate == null) continue;
      final shiftDay = DateTime(shiftDate.year, shiftDate.month, shiftDate.day);
      if (shiftDay != day) continue;

      final sStart = _parseHhmm(shift.startTime);
      final sEnd = _parseHhmm(shift.endTime);
      if (sStart == null || sEnd == null) continue;

      final overlap = _overlaps(start, end, sStart, sEnd);
      if (!overlap) continue;

      final isSameClassroom = shift.classroomCode == classroomCode;
      final isDuplicate = isSameClassroom &&
          ShiftTimeValidators.toMinutes(start) == ShiftTimeValidators.toMinutes(sStart) &&
          ShiftTimeValidators.toMinutes(end) == ShiftTimeValidators.toMinutes(sEnd);

      final type = isDuplicate
          ? ShiftConflictType.duplicate
          : (isSameClassroom
                ? ShiftConflictType.overlapSameClassroom
                : ShiftConflictType.overbooking);

      conflicts.add(
        ShiftConflict(
          shiftCode: shift.shiftCode,
          shiftDate: shiftDay,
          startTime: sStart,
          endTime: sEnd,
          classroomCode: shift.classroomCode,
          type: type,
        ),
      );
    }

    return conflicts;
  }

  bool _overlaps(TimeOfDay aStart, TimeOfDay aEnd, TimeOfDay bStart, TimeOfDay bEnd) {
    final aS = ShiftTimeValidators.toMinutes(aStart);
    final aE = ShiftTimeValidators.toMinutes(aEnd);
    final bS = ShiftTimeValidators.toMinutes(bStart);
    final bE = ShiftTimeValidators.toMinutes(bEnd);
    return aS < bE && bS < aE;
  }

  TimeOfDay? _parseHhmm(String value) {
    // Accept `HH:mm:ss` or `HH:mm`.
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    return TimeOfDay(hour: h, minute: m);
  }
}

