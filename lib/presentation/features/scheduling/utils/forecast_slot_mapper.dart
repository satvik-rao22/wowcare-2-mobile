import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/scheduling/entities/classroom_forecast_block.dart';
import 'package:wowcare/domain/features/scheduling/entities/staff_shift.dart';

import '../model/scheduling_models.dart';
import 'scheduling_block_status_style.dart';

/// Maps forecast API blocks to timeline slots and classroom ratio icons.
class ForecastSlotMapper {
  const ForecastSlotMapper._();

  static int minutesOf(TimeOfDay t) => t.hour * 60 + t.minute;

  /// Classroom row block colour. When expected, required, and scheduled are all
  /// zero the slot stays grey (inside or outside the monitoring window).
  static TimeSlotStatus statusFromBlock(
    ClassroomForecastBlock block, {
    int? scheduledStaffOverride,
  }) {
    final scheduled = scheduledStaffOverride ?? block.scheduledStaff;
    if (_allCountsZero(
      expectedStudents: block.expectedStudents,
      requiredStaff: block.requiredStaff,
      scheduledStaff: scheduled,
    )) {
      return TimeSlotStatus.empty;
    }

    final kind = SchedulingBlockStatusStyle.parseKind(
      block.blockStatus,
      scheduledStaff: scheduled,
      requiredStaff: block.requiredStaff,
    );
    return SchedulingBlockStatusStyle.toTimeSlotStatus(kind);
  }

  static bool _allCountsZero({
    required int expectedStudents,
    required int requiredStaff,
    required int scheduledStaff,
  }) =>
      expectedStudents == 0 && requiredStaff == 0 && scheduledStaff == 0;

  static ForecastSlotDetail detailFromBlock(
    ClassroomForecastBlock block, {
    int? scheduledStaffOverride,
  }) {
    return ForecastSlotDetail(
      expectedStudents: block.expectedStudents,
      requiredStaff: block.requiredStaff,
      scheduledStaff: scheduledStaffOverride ?? block.scheduledStaff,
      blockStatus: block.blockStatus,
      blockStart: block.blockStart,
      blockEnd: block.blockEnd,
      ratioRule: block.ratioRule,
      withinMonitoringWindow: block.withinMonitoringWindow,
      classroomCode: block.classroomCode,
      staffShiftCodes: block.staffShiftCodes,
    );
  }

  /// Day/week compliance icon: only [withinMonitoringWindow] under-ratio counts.
  static ClassroomRatioStatus ratioFromBlocksForWeek(
    Iterable<ClassroomForecastBlock> blocks, {
    DateTime? filterDate,
    List<StaffShift>? shiftsForScheduledCount,
  }) {
    var hasUnder = false;
    for (final block in blocks) {
      if (filterDate != null && !_sameCalendarDay(block.blockDate, filterDate)) {
        continue;
      }
      if (!block.withinMonitoringWindow) continue;

      final scheduled = _scheduledStaffForBlock(
        block,
        shifts: shiftsForScheduledCount,
        filterDate: filterDate,
      );
      if (_allCountsZero(
        expectedStudents: block.expectedStudents,
        requiredStaff: block.requiredStaff,
        scheduledStaff: scheduled,
      )) {
        continue;
      }
      final kind = SchedulingBlockStatusStyle.parseKind(
        block.blockStatus,
        scheduledStaff: scheduled,
        requiredStaff: block.requiredStaff,
      );
      if (kind == SchedulingBlockStatusKind.underRatio) {
        hasUnder = true;
        break;
      }
    }
    return hasUnder
        ? ClassroomRatioStatus.underRatio
        : ClassroomRatioStatus.inRatio;
  }

  static bool _sameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static ({
    List<TimeSlotStatus> slots,
    List<ForecastSlotDetail?> details,
    int dayStartMinutes,
    int slotMinutes,
  }) buildTimeline({
    required int windowStartMinutes,
    required int windowEndMinutes,
    required int slotMinutes,
    required Iterable<ClassroomForecastBlock> blocks,
    DateTime? filterDate,
    Iterable<String>? staffShiftCodesFilter,
    List<StaffShift>? shiftsForScheduledCount,
  }) {
    final slot = slotMinutes.clamp(1, 24 * 60);
    if (windowEndMinutes <= windowStartMinutes) {
      return (
        slots: const <TimeSlotStatus>[],
        details: const <ForecastSlotDetail?>[],
        dayStartMinutes: windowStartMinutes,
        slotMinutes: slot,
      );
    }

    final slotCount =
        ((windowEndMinutes - windowStartMinutes) / slot).ceil().clamp(1, 96);
    final slots = List<TimeSlotStatus>.filled(slotCount, TimeSlotStatus.empty);
    final details = List<ForecastSlotDetail?>.filled(slotCount, null);

    for (var i = 0; i < slotCount; i++) {
      final slotStart = windowStartMinutes + i * slot;
      final slotEnd = slotStart + slot;

      ClassroomForecastBlock? bestBlock;
      var bestOverlap = 0;

      for (final block in blocks) {
        if (!_blockMatchesFilters(
          block,
          filterDate: filterDate,
          staffShiftCodesFilter: staffShiftCodesFilter,
        )) {
          continue;
        }

        final start = minutesOf(block.blockStart);
        final end = minutesOf(block.blockEnd);
        if (start >= slotEnd || end <= slotStart) continue;

        final overlap = (end < slotEnd ? end : slotEnd) -
            (start > slotStart ? start : slotStart);

        if (overlap > bestOverlap) {
          bestOverlap = overlap;
          bestBlock = block;
        }
      }

      if (bestBlock != null) {
        final scheduled = _scheduledStaffForBlock(
          bestBlock,
          shifts: shiftsForScheduledCount,
          filterDate: filterDate,
        );
        details[i] = detailFromBlock(
          bestBlock,
          scheduledStaffOverride: scheduled,
        );
        slots[i] = statusFromBlock(
          bestBlock,
          scheduledStaffOverride: scheduled,
        );
      }
    }

    return (
      slots: slots,
      details: details,
      dayStartMinutes: windowStartMinutes,
      slotMinutes: slot,
    );
  }

  static int _scheduledStaffForBlock(
    ClassroomForecastBlock block, {
    List<StaffShift>? shifts,
    DateTime? filterDate,
  }) {
    if (shifts == null || shifts.isEmpty) return block.scheduledStaff;

    final blockStart = minutesOf(block.blockStart);
    final blockEnd = minutesOf(block.blockEnd);
    final codes = block.staffShiftCodes.map((c) => c.trim()).toSet();
    final useCodeFilter = codes.isNotEmpty;

    var count = 0;
    for (final shift in shifts) {
      if (shift.classroomCode.trim() != block.classroomCode.trim()) continue;
      if (filterDate != null &&
          !_sameCalendarDay(shift.shiftDate, filterDate)) {
        continue;
      }
      if (useCodeFilter && !codes.contains(shift.shiftCode.trim())) continue;

      final shiftStart = minutesOf(shift.startTime);
      final shiftEnd = minutesOf(shift.endTime);
      if (shiftStart < blockEnd && shiftEnd > blockStart) {
        count++;
      }
    }

    return count > 0 ? count : block.scheduledStaff;
  }

  static bool _blockMatchesFilters(
    ClassroomForecastBlock block, {
    DateTime? filterDate,
    Iterable<String>? staffShiftCodesFilter,
  }) {
    if (staffShiftCodesFilter != null &&
        staffShiftCodesFilter.isNotEmpty &&
        block.staffShiftCodes.isNotEmpty) {
      final matches = block.staffShiftCodes
          .any((code) => staffShiftCodesFilter.contains(code));
      if (!matches) return false;
    }
    if (filterDate != null) {
      if (!_sameCalendarDay(block.blockDate, filterDate)) return false;
    }
    return true;
  }
}
