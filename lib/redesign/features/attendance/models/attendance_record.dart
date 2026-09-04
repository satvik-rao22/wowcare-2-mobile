import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/attendance/models/attendance_audience.dart';
import 'package:wowcare/redesign/features/attendance/models/attendance_method.dart';
import 'package:wowcare/redesign/features/attendance/models/clock_time.dart';
import 'package:wowcare/redesign/features/attendance/models/transfer_trail.dart';

/// One day's attendance for one person, student or staff.
///
/// Mirrors `StudentAttendanceDailyItem` and `StaffAttendanceDailyItem` field
/// for field, so linking the real call is a mapper and nothing else. The two
/// entities differ only in what the row's second column is called, which is
/// why [scopeLabel] reads a classroom for a student and a role for a staff
/// member.
@immutable
class AttendanceRecord extends Equatable {
  const AttendanceRecord({
    required this.id,
    required this.fullName,
    required this.initials,
    required this.audience,
    required this.status,
    required this.classroomName,
    required this.isExpectedToday,
    this.roleLabel = '',
    this.expectedTime,
    this.signedInTime,
    this.signedInBy,
    this.signedInMethod,
    this.signedOutTime,
    this.signedOutBy,
    this.signedOutMethod,
    this.absenceReason,
    this.transfer,
  });

  final String id;
  final String fullName;
  final String initials;
  final AttendanceAudience audience;
  final AttendanceStatus status;

  /// The classroom this row belongs to. Groups the students list, and scopes
  /// a staff member on 4c.
  final String classroomName;

  /// A staff member's designation and shift: "Lead · Sunflower · 8:00 to
  /// 4:00". Empty for a student.
  final String roleLabel;

  /// The honest replacement for an arrival time the API does not hold. False
  /// makes a sign-in an override, and the two forms say so.
  final bool isExpectedToday;

  /// A staff member's shift start, which is rostered and which the app
  /// already holds. Null for a student: an expected arrival time per student
  /// is not something the API keeps, and [isExpectedToday] is what stands in
  /// its place.
  final ClockTime? expectedTime;

  final ClockTime? signedInTime;
  final String? signedInBy;
  final AttendanceMethod? signedInMethod;

  final ClockTime? signedOutTime;
  final String? signedOutBy;
  final AttendanceMethod? signedOutMethod;

  /// Why they are out. Only an absence carries one.
  final String? absenceReason;

  final TransferTrail? transfer;

  String get firstName => fullName.split(' ').first;

  bool get isSignedIn => status == AttendanceStatus.signedIn;
  bool get isSignedOut => status == AttendanceStatus.signedOut;
  bool get isAbsent => status == AttendanceStatus.absent;
  bool get isNotMarked => status == AttendanceStatus.notMarked;

  /// A student is placed by classroom, a staff member by what they do.
  String get scopeLabel =>
      audience.isStudents || roleLabel.isEmpty ? classroomName : roleLabel;

  /// Signing in someone who is signed out makes a second row rather than
  /// overwriting the first, so both of them can be signed in again.
  bool get canSignIn => isNotMarked || isAbsent || isSignedOut;
  bool get canSignOut => isSignedIn;

  /// Mark Absent is off once someone is here.
  bool get canMarkAbsent => isNotMarked;

  /// There is nothing to edit until a time is recorded.
  bool get canEditTimes => signedInTime != null;

  /// Only someone in the building can be moved to another classroom.
  bool get canTransfer => isSignedIn;

  @override
  List<Object?> get props => <Object?>[
    id,
    fullName,
    initials,
    audience,
    status,
    classroomName,
    roleLabel,
    isExpectedToday,
    expectedTime,
    signedInTime,
    signedInBy,
    signedInMethod,
    signedOutTime,
    signedOutBy,
    signedOutMethod,
    absenceReason,
    transfer,
  ];
}
