import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/students/models/student_summary.dart';

/// Everything 5a draws, in one fetch.
///
/// [classroomNames] is the order the groups appear in, and it is the school's
/// own classroom order rather than whatever the roster page happened to
/// return. [tagNames] and [guardianNames] are what the filter sheet offers;
/// both are already loaded, which is why Tags can be a searchable dropdown.
@immutable
class RosterSnapshot extends Equatable {
  const RosterSnapshot({
    this.students = const <StudentSummary>[],
    this.upcoming = const <StudentSummary>[],
    this.classroomNames = const <String>[],
    this.tagNames = const <String>[],
    this.guardianNames = const <String>[],
    this.asOfLabel,
  });

  /// Active students, in the order the roster returned them.
  final List<StudentSummary> students;

  /// Enrolled, not started: the dashed rows under "Starting soon".
  final List<StudentSummary> upcoming;

  final List<String> classroomNames;
  final List<String> tagNames;
  final List<String> guardianNames;

  /// "8:12 this morning", when this came off the phone rather than the wire.
  final String? asOfLabel;

  int get activeCount => students.length;
  int get upcomingCount => upcoming.length;

  bool get isEmpty => students.isEmpty && upcoming.isEmpty;

  @override
  List<Object?> get props => [
    students,
    upcoming,
    classroomNames,
    tagNames,
    guardianNames,
    asOfLabel,
  ];
}
