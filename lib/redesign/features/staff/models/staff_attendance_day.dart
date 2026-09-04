import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';

/// One day of a staff member's attendance history (6c Attendance).
///
/// Read off `/api/v1/staff-attendance/profile`, which is the call the
/// existing `staff_attendance_profile.dart` screen already makes. Timesheets
/// are on the module's costly list, so this reports and totals nothing more.
@immutable
class StaffAttendanceDay extends Equatable {
  const StaffAttendanceDay({
    required this.date,
    required this.status,
    this.startMinutes,
    this.endMinutes,
    this.classroom = '',
    this.note = '',
  });

  final DateTime date;
  final AttendanceStatus status;

  /// When they signed in, and when they signed out. A day still running has a
  /// start and no end.
  final int? startMinutes;
  final int? endMinutes;

  /// Where they worked, when it was not their usual classroom.
  final String classroom;

  /// "Called in sick 6:40", or whatever the record carries.
  final String note;

  bool get isStillIn => startMinutes != null && endMinutes == null;

  /// Hours on the clock. Null when there is nothing to total.
  int? get workedMinutes => startMinutes == null || endMinutes == null
      ? null
      : endMinutes! - startMinutes!;

  @override
  List<Object?> get props => [
    date,
    status,
    startMinutes,
    endMinutes,
    classroom,
    note,
  ];
}

/// The month heading over the day list: how many days were worked, how many
/// were missed, and the hours behind them.
@immutable
class StaffAttendanceSummary extends Equatable {
  const StaffAttendanceSummary({
    required this.month,
    this.daysAttended = 0,
    this.daysAbsent = 0,
    this.workedMinutes = 0,
  });

  /// The month the days below belong to.
  final DateTime month;
  final int daysAttended;
  final int daysAbsent;
  final int workedMinutes;

  @override
  List<Object?> get props => [month, daysAttended, daysAbsent, workedMinutes];
}
