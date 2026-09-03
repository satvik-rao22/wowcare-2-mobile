import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One day on a staff member's week strip (3S2's My shifts).
@immutable
class ShiftDay extends Equatable {
  const ShiftDay({
    required this.weekdayLabel,
    required this.dayNumber,
    this.classroomName,
    this.window,
    this.breakWindow,
    this.isToday = false,
    this.isCovering = false,
  });

  /// "THU".
  final String weekdayLabel;
  final int dayNumber;

  /// Null on a day off.
  final String? classroomName;
  final String? window;
  final String? breakWindow;

  final bool isToday;
  final bool isCovering;

  bool get isDayOff => classroomName == null;

  @override
  List<Object?> get props => [
    weekdayLabel,
    dayNumber,
    classroomName,
    window,
    breakWindow,
    isToday,
    isCovering,
  ];
}

/// One recorded day on the attendance list under the totals (3S2, 3P2).
@immutable
class AttendanceDay extends Equatable {
  const AttendanceDay({
    required this.label,
    this.from,
    this.to,
    this.absenceReason,
  });

  /// "Mon · 17 Aug".
  final String label;
  final String? from;
  final String? to;

  /// Set, the day is an absence. The reason may itself be empty.
  final String? absenceReason;

  bool get isAbsent => absenceReason != null;

  @override
  List<Object?> get props => [label, from, to, absenceReason];
}

/// The attendance block under a week strip: a range, three totals, and the
/// days behind them (3S2, and 3P2 for a student).
@immutable
class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.rangeLabel,
    required this.daysAttended,
    required this.hoursAttended,
    required this.minutesAttended,
    required this.daysAbsent,
    required this.days,
  });

  /// "1 Aug – 20 Aug".
  final String rangeLabel;

  final int daysAttended;
  final int hoursAttended;
  final int minutesAttended;
  final int daysAbsent;

  final List<AttendanceDay> days;

  @override
  List<Object?> get props => [
    rangeLabel,
    daysAttended,
    hoursAttended,
    minutesAttended,
    daysAbsent,
    days,
  ];
}
