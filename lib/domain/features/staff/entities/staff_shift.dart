import 'package:equatable/equatable.dart';

/// Summary hours and timeline blocks for one staff member on a single day.
class StaffShiftDaySummary extends Equatable {
  const StaffShiftDaySummary({
    required this.availableHours,
    required this.scheduledHours,
    required this.unscheduledHours,
    this.blocks = const [],
  });

  final int availableHours;
  final int scheduledHours;
  final int unscheduledHours;

  /// Timeline blocks for the day calendar (work + optional lunch break).
  final List<StaffShiftTimelineBlock> blocks;

  static const empty = StaffShiftDaySummary(
    availableHours: 0,
    scheduledHours: 0,
    unscheduledHours: 0,
  );

  @override
  List<Object?> get props =>
      [availableHours, scheduledHours, unscheduledHours, blocks];
}

class StaffShiftTimelineBlock extends Equatable {
  const StaffShiftTimelineBlock({
    required this.room,
    required this.start,
    required this.end,
    this.isBreak = false,
    this.shiftCode = '',
  });

  /// Classroom code/label or "Lunch Break".
  final String room;

  /// `hh:mm:ss a` — consumed by [StaffDayScheduleCalendar].
  final String start;
  final String end;
  final bool isBreak;

  /// Source shift identity (empty for legacy/mocked data). Lets the view
  /// screen re-fetch the full record via `GET /api/v1/staff-shifts/{shiftCode}`.
  final String shiftCode;

  @override
  List<Object?> get props => [room, start, end, isBreak, shiftCode];
}
