import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/classrooms/models/classroom_summary.dart';

/// Which slice of the floor the chips are showing (7a).
enum ClassroomSegment { all, overRatio, empty }

/// The whole classrooms screen in one object (7a).
///
/// The school-level figures on the navy card are their own reading, not a sum
/// of [classrooms]: they come from the capacity, FTE and attendance-summary
/// calls (`SchoolCapacity`, `SchoolFte`, the by-classrooms summary), which the
/// app already makes and draws nowhere.
@immutable
class ClassroomBoard extends Equatable {
  const ClassroomBoard({
    this.date,
    this.studentsPresent = 0,
    this.staffOnDuty = 0,
    this.enrolled = 0,
    this.places = 0,
    this.classrooms = const <ClassroomSummary>[],
    this.unassignedStudents = 0,
  });

  final DateTime? date;

  /// Students signed in across the school right now.
  final int studentsPresent;

  /// Staff on the clock across the school right now.
  final int staffOnDuty;

  /// Students on the roll, and the places there are for them.
  final int enrolled;
  final int places;

  final List<ClassroomSummary> classrooms;

  /// Students at the school who are in no classroom at all (7j's empty copy).
  final int unassignedStudents;

  int get classroomCount => classrooms.length;
  bool get isEmpty => classrooms.isEmpty;

  int get percentFull => places == 0 ? 0 : ((enrolled / places) * 100).round();
  double get fillFraction =>
      places == 0 ? 0 : (enrolled / places).clamp(0, 1).toDouble();

  int get overRatioCount => classrooms.where((r) => !r.isInRatio).length;
  int get emptyCount => classrooms.where((r) => r.isEmpty).length;

  /// How many classrooms a chip carries after its own filter.
  int countFor(ClassroomSegment segment) => switch (segment) {
    ClassroomSegment.all => classroomCount,
    ClassroomSegment.overRatio => overRatioCount,
    ClassroomSegment.empty => emptyCount,
  };

  @override
  List<Object?> get props => [
    date,
    studentsPresent,
    staffOnDuty,
    enrolled,
    places,
    classrooms,
    unassignedStudents,
  ];
}
