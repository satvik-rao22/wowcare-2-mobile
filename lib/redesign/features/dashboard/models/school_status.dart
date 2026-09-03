import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// How a population divides across today's four attendance states.
///
/// Written students-first and with two states only where the design says so;
/// here all four are carried because the school-status card draws all four.
@immutable
class AttendanceBreakdown extends Equatable {
  const AttendanceBreakdown({
    this.signedIn = 0,
    this.signedOut = 0,
    this.absent = 0,
    this.notMarked = 0,
  });

  final int signedIn;
  final int signedOut;
  final int absent;
  final int notMarked;

  int get total => signedIn + signedOut + absent + notMarked;

  /// Each state's share of [total], in the trough's own order.
  List<double> get fractions {
    if (total == 0) return const <double>[0, 0, 0, 0];
    return <double>[
      signedIn / total,
      signedOut / total,
      absent / total,
      notMarked / total,
    ];
  }

  @override
  List<Object?> get props => [signedIn, signedOut, absent, notMarked];
}

/// The one card an Admin reads first: the school, today (3A1).
@immutable
class SchoolStatus extends Equatable {
  const SchoolStatus({
    required this.classrooms,
    required this.capacity,
    required this.occupancyPercent,
    required this.studentsEnrolled,
    required this.studentsExpected,
    required this.students,
    required this.staffExpected,
    required this.staff,
  });

  final int classrooms;
  final int capacity;

  /// Full time equivalent, as a whole percent.
  final int occupancyPercent;

  final int studentsEnrolled;
  final int studentsExpected;
  final AttendanceBreakdown students;

  final int staffExpected;
  final AttendanceBreakdown staff;

  @override
  List<Object?> get props => [
    classrooms,
    capacity,
    occupancyPercent,
    studentsEnrolled,
    studentsExpected,
    students,
    staffExpected,
    staff,
  ];
}
