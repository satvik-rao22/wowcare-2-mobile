import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/scheduling/entities/staff_shift.dart';

import '../model/scheduling_models.dart';
import 'forecast_slot_mapper.dart';

/// Builds staff-row Gantt slots from shift API times (work / break), not forecast.
class StaffShiftSlotMapper {
  const StaffShiftSlotMapper._();

  static ({
    List<StaffShiftSlotStatus> slots,
    List<StaffShiftSlotDetail?> details,
    int dayStartMinutes,
    int slotMinutes,
  })
  buildTimeline({
    required int windowStartMinutes,
    required int windowEndMinutes,
    required int slotMinutes,
    required StaffShift shift,
  }) {
    final slot = slotMinutes.clamp(1, 24 * 60);
    if (windowEndMinutes <= windowStartMinutes) {
      return (
        slots: const <StaffShiftSlotStatus>[],
        details: const <StaffShiftSlotDetail?>[],
        dayStartMinutes: windowStartMinutes,
        slotMinutes: slot,
      );
    }

    final slotCount = ((windowEndMinutes - windowStartMinutes) / slot)
        .ceil()
        .clamp(1, 96);
    final slots = List<StaffShiftSlotStatus>.filled(
      slotCount,
      StaffShiftSlotStatus.empty,
    );
    final details = List<StaffShiftSlotDetail?>.filled(slotCount, null);

    final shiftStart = ForecastSlotMapper.minutesOf(shift.startTime);
    final shiftEnd = ForecastSlotMapper.minutesOf(shift.endTime);
    final breakStart = shift.breakStartTime != null
        ? ForecastSlotMapper.minutesOf(shift.breakStartTime!)
        : null;
    final breakEnd = shift.breakEndTime != null
        ? ForecastSlotMapper.minutesOf(shift.breakEndTime!)
        : null;
    final hasBreak =
        breakStart != null && breakEnd != null && breakEnd > breakStart;

    for (var i = 0; i < slotCount; i++) {
      final slotStart = windowStartMinutes + i * slot;
      final slotEnd = slotStart + slot;

      final status = _statusForSlot(
        slotStart: slotStart,
        slotEnd: slotEnd,
        shiftStart: shiftStart,
        shiftEnd: shiftEnd,
        breakStart: hasBreak ? breakStart : null,
        breakEnd: hasBreak ? breakEnd : null,
      );

      slots[i] = status;
      details[i] = StaffShiftSlotDetail(
        status: status,
        shiftStart: shift.startTime,
        shiftEnd: shift.endTime,
        breakStart: shift.breakStartTime,
        breakEnd: shift.breakEndTime,
        classroomCode: shift.classroomCode,
        shiftCode: shift.shiftCode,
        isPublished: shift.isPublished,
      );
    }

    return (
      slots: slots,
      details: details,
      dayStartMinutes: windowStartMinutes,
      slotMinutes: slot,
    );
  }

  /// Classifies by slot center so a sliver overlap (e.g. 12:31–1:01 vs break
  /// at 1:00) does not count as break; a slot centered in break does.
  static StaffShiftSlotStatus _statusForSlot({
    required int slotStart,
    required int slotEnd,
    required int shiftStart,
    required int shiftEnd,
    required int? breakStart,
    required int? breakEnd,
  }) {
    if (slotEnd <= slotStart) return StaffShiftSlotStatus.empty;

    if (breakStart != null &&
        breakEnd != null &&
        _slotCenterInRange(slotStart, slotEnd, breakStart, breakEnd)) {
      return StaffShiftSlotStatus.breakTime;
    }

    if (_slotCenterInRange(slotStart, slotEnd, shiftStart, shiftEnd)) {
      return StaffShiftSlotStatus.workTime;
    }

    return StaffShiftSlotStatus.empty;
  }

  static bool _slotCenterInRange(
    int slotStart,
    int slotEnd,
    int rangeStart,
    int rangeEnd,
  ) {
    final center = (slotStart + slotEnd) ~/ 2;
    return center >= rangeStart && center < rangeEnd;
  }
}
