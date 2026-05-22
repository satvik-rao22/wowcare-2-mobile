import 'package:flutter/foundation.dart';

/// Ratio outcome for a classroom on a given day.
enum ClassroomRatioStatus { inRatio, underRatio }

/// Top-level view mode for the schedule screen.
enum SchedulingViewMode { week, day }

/// Per-slot status used by the day-Gantt timeline strip.
enum TimeSlotStatus { inRatio, underRatio, overRatio, empty }

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
    this.photoUrl,
    this.daySlots = const <TimeSlotStatus>[],
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

  final String? photoUrl;

  /// Status per slot for the day-Gantt timeline (ordered earliest → latest).
  final List<TimeSlotStatus> daySlots;
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
  });

  final String classroomCode;
  final String classroomName;
  final ClassroomRatioStatus ratioStatus;
  final List<StaffScheduleEntry> staff;

  /// Aggregate timeline shown next to "Class Schedule" in the day view.
  final List<TimeSlotStatus> daySlots;
}
