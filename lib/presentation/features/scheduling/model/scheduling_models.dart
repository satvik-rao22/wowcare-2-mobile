import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// Ratio outcome for a classroom on a given day.
enum ClassroomRatioStatus { inRatio, underRatio, overRatio }

/// Canonical ratio kinds aligned with forecast API `blockStatus`.
enum SchedulingBlockStatusKind {
  inRatio,
  underRatio,
  extraStaff,
  empty,
}

/// Top-level view mode for the schedule screen.
enum SchedulingViewMode { week, day }

/// Per-slot status used by the day-Gantt timeline strip.
enum TimeSlotStatus { inRatio, underRatio, overRatio, empty }

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
    required this.startTime,
    required this.endTime,
    this.isPublished = false,
    this.shiftCode,
    this.photoUrl,
    this.daySlots = const <TimeSlotStatus>[],
    this.slotDetails = const <ForecastSlotDetail?>[],
    this.timelineStartMinutes = 7 * 60,
    this.slotMinutes = 30,
  });

  final String staffName;

  /// Hours for this specific shift row (computed from start/end). Backend
  /// returns the same per-day aggregate on every shift of a staff member,
  /// which is misleading per row — we compute per-shift duration instead.
  final double scheduledHours;

  /// Total available hours for the staff member on this day (backend's
  /// aggregate). Repeats across rows of the same staff, which is intentional.
  final double availableHours;

  final String startTime;
  final String endTime;

  /// Drives the pill border style: solid for published, dotted for draft.
  final bool isPublished;

  /// Used to match forecast blocks (`staffShiftCodes`) in day view.
  final String? shiftCode;

  final String? photoUrl;

  /// Status per slot for the day-Gantt timeline (ordered earliest → latest).
  final List<TimeSlotStatus> daySlots;

  /// Parallel to [daySlots] — forecast payload for the slot popover.
  final List<ForecastSlotDetail?> slotDetails;

  /// Minutes since midnight for the first Gantt slot.
  final int timelineStartMinutes;

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
  final int slotMinutes;
}
