import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/classrooms/models/classroom_note.dart';
import 'package:wowcare/redesign/features/classrooms/models/classroom_staff_member.dart';
import 'package:wowcare/redesign/features/classrooms/models/classroom_summary.dart';
import 'package:wowcare/redesign/features/classrooms/models/roster_student.dart';

/// One classroom with everything its three tabs need (7c, 7e, 7j).
@immutable
class ClassroomDetail extends Equatable {
  const ClassroomDetail({
    required this.summary,
    this.students = const <RosterStudent>[],
    this.staff = const <ClassroomStaffMember>[],
    this.notes = const <ClassroomNote>[],
    this.upcomingStudents = const <RosterStudent>[],
    this.newNoteCount = 0,
    this.careTags = const <String>[],
    this.designations = const <String>[],
    this.others = const <ClassroomSummary>[],
  });

  final ClassroomSummary summary;

  /// The students on the roll today, in the order the API returns them.
  final List<RosterStudent> students;

  /// Students whose start date has not arrived (7d's "Upcoming").
  final List<RosterStudent> upcomingStudents;

  final List<ClassroomStaffMember> staff;
  final List<ClassroomNote> notes;

  /// How many notes arrived since the last visit.
  final int newNoteCount;

  /// Every care-need tag anyone on this roster holds, for the filter sheet.
  final List<String> careTags;

  /// Every designation the staff here hold, for the filter sheet.
  final List<String> designations;

  /// The other classrooms on the floor, for the move picker (7i). The list
  /// call that fills 7a already returns them.
  final List<ClassroomSummary> others;

  int get signedInCount => students.where((s) => s.isSignedIn).length;
  int get nappingCount => students.where((s) => s.isNapping).length;

  int countOfDuty(StaffDutyState state) =>
      staff.where((p) => p.state == state).length;

  /// Staff on the clock, break included: what the ratio counts.
  int get staffOnDuty => staff.where((p) => p.isPresent).length;

  /// The minimum staff this many students in wants.
  int get staffWanted => summary.allowedRatio <= 0
      ? 0
      : (summary.studentsPresent / summary.allowedRatio).ceil();

  ClassroomDetail copyWith({
    ClassroomSummary? summary,
    List<RosterStudent>? students,
    List<ClassroomNote>? notes,
  }) => ClassroomDetail(
    summary: summary ?? this.summary,
    students: students ?? this.students,
    staff: staff,
    notes: notes ?? this.notes,
    upcomingStudents: upcomingStudents,
    newNoteCount: newNoteCount,
    careTags: careTags,
    designations: designations,
    others: others,
  );

  @override
  List<Object?> get props => [
    summary,
    students,
    upcomingStudents,
    staff,
    notes,
    newNoteCount,
    careTags,
    designations,
    others,
  ];
}
