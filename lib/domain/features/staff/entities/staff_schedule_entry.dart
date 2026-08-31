import 'package:equatable/equatable.dart';

/// One work-schedule entry for `PATCH /api/v1/staff-schedules/{staffCode}`.
///
/// Replaces the raw `Map<String, dynamic>` entries the edit-schedule view built
/// inline. Times are the already-formatted local-time strings the view produced
/// (e.g. `"09:00:00"`); this model only carries them. [toPayload] reproduces the
/// exact Map, key-for-key.
class StaffWorkScheduleEntry extends Equatable {
  const StaffWorkScheduleEntry({
    required this.dayOfWeek,
    required this.workStartTime,
    required this.workEndTime,
  });

  final String dayOfWeek;
  final String workStartTime;
  final String workEndTime;

  Map<String, dynamic> toPayload() => {
    'dayOfWeek': dayOfWeek,
    'workStartTime': workStartTime,
    'workEndTime': workEndTime,
  };

  @override
  List<Object?> get props => [dayOfWeek, workStartTime, workEndTime];
}

/// One break-schedule entry for `PATCH /api/v1/staff-schedules/{staffCode}`.
///
/// Replaces the raw `Map<String, dynamic>` entries the edit-schedule view built
/// inline. [toPayload] reproduces the exact Map, key-for-key (including the
/// literal `breakType`, e.g. `"LUNCH"`, the view supplied).
class StaffBreakScheduleEntry extends Equatable {
  const StaffBreakScheduleEntry({
    required this.dayOfWeek,
    required this.breakType,
    required this.breakStartTime,
    required this.breakEndTime,
  });

  final String dayOfWeek;
  final String breakType;
  final String breakStartTime;
  final String breakEndTime;

  Map<String, dynamic> toPayload() => {
    'dayOfWeek': dayOfWeek,
    'breakType': breakType,
    'breakStartTime': breakStartTime,
    'breakEndTime': breakEndTime,
  };

  @override
  List<Object?> get props => [
    dayOfWeek,
    breakType,
    breakStartTime,
    breakEndTime,
  ];
}
