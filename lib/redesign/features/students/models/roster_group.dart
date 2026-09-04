import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/core/widgets/attendance_dot.dart';
import 'package:wowcare/redesign/features/students/models/student_summary.dart';

/// One classroom's students, under its eyebrow (5a).
///
/// The tallies are counted here rather than fetched: the roster already holds
/// today's status for every student it drew, so the header's
/// `14 students · 8 in · 1 out · 2 absent · 3 not marked` costs nothing new.
@immutable
class RosterGroup extends Equatable {
  const RosterGroup({required this.classroomName, required this.students});

  final String classroomName;
  final List<StudentSummary> students;

  int countOf(AttendanceStatus status) =>
      students.where((s) => s.attendance == status).length;

  int get signedIn => countOf(AttendanceStatus.signedIn);
  int get signedOut => countOf(AttendanceStatus.signedOut);
  int get absent => countOf(AttendanceStatus.absent);
  int get notMarked => countOf(AttendanceStatus.notMarked);

  @override
  List<Object?> get props => [classroomName, students];
}
