import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';

/// One day of a student's attendance history (5c Attendance).
///
/// Mirrors `StudentAttendanceDailyItem`: the day, its in and out times, where
/// they were recorded, and the hours they add up to.
@immutable
class AttendanceDay extends Equatable {
  const AttendanceDay({
    required this.dateLabel,
    required this.detail,
    required this.status,
    required this.hoursLabel,
  });

  /// "Thu 20 Aug".
  final String dateLabel;

  /// "8:05 – 16:40 · kiosk", "Sick, called 7:20".
  final String detail;

  final AttendanceStatus status;

  /// "8h 35m", "still in", "—".
  final String hoursLabel;

  @override
  List<Object?> get props => [dateLabel, detail, status, hoursLabel];
}

/// The month a run of [AttendanceDay]s belongs to, with its summary line.
@immutable
class AttendanceMonth extends Equatable {
  const AttendanceMonth({
    required this.name,
    required this.daysIn,
    required this.absent,
    required this.hours,
    this.days = const <AttendanceDay>[],
  });

  /// "August".
  final String name;
  final int daysIn;
  final int absent;
  final int hours;
  final List<AttendanceDay> days;

  @override
  List<Object?> get props => [name, daysIn, absent, hours, days];
}
