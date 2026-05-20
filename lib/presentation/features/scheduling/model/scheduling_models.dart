import 'package:flutter/foundation.dart';

/// Ratio outcome for a classroom on a given day.
enum ClassroomRatioStatus { inRatio, underRatio }

/// A single staff member's schedule entry for one day.
@immutable
class StaffScheduleEntry {
  const StaffScheduleEntry({
    required this.staffName,
    required this.scheduledHours,
    required this.availableHours,
    required this.startTime,
    required this.endTime,
    this.photoUrl,
  });

  final String staffName;
  final int scheduledHours;
  final int availableHours;
  final String startTime;
  final String endTime;
  final String? photoUrl;
}

/// One classroom's per-day schedule (used by both week and day views).
@immutable
class ClassroomDaySchedule {
  const ClassroomDaySchedule({
    required this.classroomCode,
    required this.classroomName,
    required this.ratioStatus,
    this.staff = const <StaffScheduleEntry>[],
  });

  final String classroomCode;
  final String classroomName;
  final ClassroomRatioStatus ratioStatus;
  final List<StaffScheduleEntry> staff;
}
