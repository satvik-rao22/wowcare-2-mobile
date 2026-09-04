import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/attendance/models/attendance_record.dart';

/// One of a guardian's children, and the month behind them.
@immutable
class GuardianChildAttendance extends Equatable {
  const GuardianChildAttendance({
    required this.today,
    required this.days,
    required this.daysIn,
    required this.daysAbsent,
    required this.hours,
  });

  /// Today's row, the same record the classroom list holds.
  final AttendanceRecord today;

  /// The last few days, newest first.
  final List<GuardianDay> days;

  final int daysIn;
  final int daysAbsent;
  final int hours;

  @override
  List<Object?> get props => <Object?>[today, days, daysIn, daysAbsent, hours];
}

/// One past day on a guardian's list.
@immutable
class GuardianDay extends Equatable {
  const GuardianDay({
    required this.dateLabel,
    required this.detail,
    required this.trailing,
    required this.status,
  });

  /// "Wed 19 Aug", or "Today · Thu 20 Aug".
  final String dateLabel;

  /// "8:35 to 3:40 · you collected Amara".
  final String detail;

  /// "7h 5m", "Absent", "In now".
  final String trailing;

  final AttendanceStatus status;

  @override
  List<Object?> get props => <Object?>[dateLabel, detail, trailing, status];
}
