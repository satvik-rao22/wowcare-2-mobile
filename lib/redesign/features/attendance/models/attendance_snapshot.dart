import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/attendance/models/attendance_record.dart';
import 'package:wowcare/redesign/features/attendance/models/guardian_child_attendance.dart';
import 'package:wowcare/redesign/features/attendance/models/self_shift.dart';
import 'package:wowcare/redesign/features/attendance/models/staff_gap.dart';

/// One day, as it came back.
///
/// The two head counts on the Students / Staff switch are here whichever list
/// was fetched, because the real screen gets them from the two expected
/// summary cards rather than by counting the page it is showing.
@immutable
class AttendanceSnapshot extends Equatable {
  const AttendanceSnapshot({
    this.rows = const <AttendanceRecord>[],
    this.classroomNames = const <String>[],
    this.enrolled = const <String, int>{},
    this.allowedRatio = const <String, int>{},
    this.staffPresent = const <String, int>{},
    this.schoolClassroomCount = 0,
    this.studentsTotal = 0,
    this.studentsSignedIn = 0,
    this.staffTotal = 0,
    this.staffSignedIn = 0,
    this.staffMinutesToday = 0,
    this.selfShift,
    this.staffGap,
    this.children = const <GuardianChildAttendance>[],
  });

  final List<AttendanceRecord> rows;

  /// The classrooms this list covers, in the school's own order.
  final List<String> classroomNames;

  /// How many are on each classroom's roll.
  final Map<String, int> enrolled;

  /// Students per staff member each classroom is allowed.
  final Map<String, int> allowedRatio;

  /// Staff signed in and standing in each classroom right now.
  final Map<String, int> staffPresent;

  /// Every classroom the school has, for the admin scope note.
  final int schoolClassroomCount;

  final int studentsTotal;
  final int studentsSignedIn;
  final int staffTotal;
  final int staffSignedIn;

  /// Minutes on the clock across everyone signed in, for 4c's foot note.
  final int staffMinutesToday;

  /// The staff member's own day. Only the staff lens has one.
  final SelfShift? selfShift;

  /// The classroom that runs short later today, on the staff list.
  final StaffGap? staffGap;

  /// A guardian's children. Only the guardian lens has any.
  final List<GuardianChildAttendance> children;

  bool get isEmpty => rows.isEmpty && children.isEmpty;

  @override
  List<Object?> get props => <Object?>[
    rows,
    classroomNames,
    enrolled,
    allowedRatio,
    staffPresent,
    schoolClassroomCount,
    studentsTotal,
    studentsSignedIn,
    staffTotal,
    staffSignedIn,
    staffMinutesToday,
    selfShift,
    staffGap,
    children,
  ];
}
