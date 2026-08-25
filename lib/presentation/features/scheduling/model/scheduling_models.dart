import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ratio outcome for a classroom on a given day.
enum ClassroomRatioStatus { inRatio, underRatio, overRatio }

/// Canonical ratio kinds aligned with forecast API `blockStatus`.
enum SchedulingBlockStatusKind { inRatio, underRatio, extraStaff, empty }

/// Top-level view mode for the schedule screen.
enum SchedulingViewMode { week, day }

/// Per-slot status used by the classroom day-Gantt (forecast ratio only).
enum TimeSlotStatus { inRatio, underRatio, overRatio, empty }

/// Per-slot status for staff day-Gantt rows (shift work/break only).
enum StaffShiftSlotStatus { empty, workTime, breakTime }

/// Payload for one staff shift slot (hover / tap); not forecast ratio data.
@immutable
class StaffShiftSlotDetail {
  const StaffShiftSlotDetail({
    required this.status,
    this.shiftStart,
    this.shiftEnd,
    this.breakStart,
    this.breakEnd,
    this.classroomCode = '',
    this.shiftCode = '',
    this.isPublished = false,
  });

  final StaffShiftSlotStatus status;
  final TimeOfDay? shiftStart;
  final TimeOfDay? shiftEnd;
  final TimeOfDay? breakStart;
  final TimeOfDay? breakEnd;
  final String classroomCode;
  final String shiftCode;
  final bool isPublished;

  bool get hasShiftData =>
      status != StaffShiftSlotStatus.empty &&
      shiftStart != null &&
      shiftEnd != null;
}

/// Forecast metrics for one monitoring block (day-view slot dialog).
@immutable
class ForecastSlotDetail {
  const ForecastSlotDetail({
    required this.expectedStudents,
    required this.requiredStaff,
    required this.scheduledStaff,
    this.blockStatus = '',
    this.blockStart,
    this.blockEnd,
    this.ratioRule = 0,
    this.withinMonitoringWindow = true,
    this.classroomCode = '',
    this.staffShiftCodes = const <String>[],
  });

  final int expectedStudents;
  final int requiredStaff;
  final int scheduledStaff;
  final String blockStatus;
  final TimeOfDay? blockStart;
  final TimeOfDay? blockEnd;
  final int ratioRule;
  final bool withinMonitoringWindow;
  final String classroomCode;
  final List<String> staffShiftCodes;

  /// True when this slot was backed by a forecast API block.
  bool get hasForecastData =>
      blockStatus.trim().isNotEmpty ||
      blockStart != null ||
      blockEnd != null ||
      expectedStudents > 0 ||
      requiredStaff > 0 ||
      scheduledStaff > 0 ||
      ratioRule > 0;
}

/// A single staff member's schedule entry for one day.
@immutable
class StaffScheduleEntry {
  const StaffScheduleEntry({
    required this.staffName,
    required this.scheduledHours,
    required this.availableHours,
    required this.unscheduledHours,
    required this.startTime,
    required this.endTime,
    this.staffCode = '',
    this.isPublished = false,
    this.shiftCode,
    this.photoUrl,
    this.profilePhotoAssetCode,
    this.staffDaySlots = const <StaffShiftSlotStatus>[],
    this.staffSlotDetails = const <StaffShiftSlotDetail?>[],
    this.timelineStartMinutes = 7 * 60,
    this.timelineEndMinutes = 19 * 60,
    this.slotMinutes = 30,
  });

  final String staffName;
  final String staffCode;

  /// Per-day totals from `POST /staff-shifts/hours/range` (summed per staff/day).
  final double scheduledHours;

  /// Per-day totals from the staff-shifts API (`availableHours`).
  final double availableHours;

  /// Per-day totals from the staff-shifts API (`unscheduledHours`).
  final double unscheduledHours;

  final String startTime;
  final String endTime;

  /// Drives the pill border style: solid for published, dotted for draft.
  final bool isPublished;

  final String? shiftCode;

  final String? photoUrl;

  /// Staff profile asset code for [DocumentImageWidget].
  final String? profilePhotoAssetCode;

  /// Staff row: work/break colours across the full school-day window.
  final List<StaffShiftSlotStatus> staffDaySlots;

  /// Staff row: shift timing payload for hover/tap.
  final List<StaffShiftSlotDetail?> staffSlotDetails;

  /// Minutes since midnight for the first Gantt slot.
  final int timelineStartMinutes;

  /// School-day end from regular schedule (axis shows through this time).
  final int timelineEndMinutes;

  /// Width of each coloured block in minutes (from regular-schedule duration).
  final int slotMinutes;
}

/// One classroom's per-day schedule (used by both week and day views).
@immutable
class ClassroomDaySchedule {
  const ClassroomDaySchedule({
    required this.classroomCode,
    required this.classroomName,
    required this.ratioStatus,
    this.staff = const <StaffScheduleEntry>[],
    this.daySlots = const <TimeSlotStatus>[],
    this.slotDetails = const <ForecastSlotDetail?>[],
    this.timelineStartMinutes = 7 * 60,
    this.timelineEndMinutes = 19 * 60,
    this.slotMinutes = 30,
  });

  final String classroomCode;
  final String classroomName;
  final ClassroomRatioStatus ratioStatus;
  final List<StaffScheduleEntry> staff;

  /// Aggregate timeline shown next to the classroom row in the day view.
  final List<TimeSlotStatus> daySlots;

  final List<ForecastSlotDetail?> slotDetails;
  final int timelineStartMinutes;
  final int timelineEndMinutes;
  final int slotMinutes;
}
