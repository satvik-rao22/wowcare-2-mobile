import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:wowcare/redesign/features/classrooms/models/classroom_summary.dart';

/// A population's day, in the four states the app names (7f).
@immutable
class DayBreakdown extends Equatable {
  const DayBreakdown({
    this.signedIn = 0,
    this.notMarked = 0,
    this.absent = 0,
    this.signedOut = 0,
  });

  final int signedIn;
  final int notMarked;
  final int absent;
  final int signedOut;

  int get expected => signedIn + notMarked + absent + signedOut;

  @override
  List<Object?> get props => [signedIn, notMarked, absent, signedOut];
}

/// A student arriving in or leaving this classroom on a date already booked
/// in Movements (7f). Read-only: booking one is Movements' job.
@immutable
class ClassroomMovement extends Equatable {
  const ClassroomMovement({
    required this.name,
    required this.detail,
    required this.isArriving,
  });

  final String name;

  /// "From Acorn on 1 Sep", "New enrollment, starts 8 Sep".
  final String detail;

  final bool isArriving;

  @override
  List<Object?> get props => [name, detail, isArriving];
}

/// One line of the navy "Across the center" table (7f).
@immutable
class CenterRatioRow extends Equatable {
  const CenterRatioRow({
    required this.name,
    required this.studentsPresent,
    required this.staffPresent,
    required this.state,
    this.staffNeeded = 0,
  });

  final String name;
  final int studentsPresent;
  final int staffPresent;
  final ClassroomRatioState state;

  /// How many more staff a short classroom wants.
  final int staffNeeded;

  @override
  List<Object?> get props => [
    name,
    studentsPresent,
    staffPresent,
    state,
    staffNeeded,
  ];
}

/// The school, summarised under one classroom's record (7f).
@immutable
class CenterSummary extends Equatable {
  const CenterSummary({
    this.classroomCount = 0,
    this.totalPlaces = 0,
    this.fullTimeEquivalent = 0,
    this.rows = const <CenterRatioRow>[],
  });

  final int classroomCount;
  final int totalPlaces;

  /// `SchoolFte.schoolFte`, one decimal place.
  final double fullTimeEquivalent;

  final List<CenterRatioRow> rows;

  @override
  List<Object?> get props => [
    classroomCount,
    totalPlaces,
    fullTimeEquivalent,
    rows,
  ];
}

/// The photo on a classroom's record, once one is on file.
@immutable
class ClassroomPhoto extends Equatable {
  const ClassroomPhoto({required this.fileName});

  final String fileName;

  @override
  List<Object?> get props => [fileName];
}

/// The classroom's own record (7f), reached from the header card.
@immutable
class ClassroomProfile extends Equatable {
  const ClassroomProfile({
    required this.summary,
    this.photo,
    this.students = const DayBreakdown(),
    this.staff = const DayBreakdown(),
    this.movements = const <ClassroomMovement>[],
    this.center = const CenterSummary(),
  });

  final ClassroomSummary summary;
  final ClassroomPhoto? photo;

  final DayBreakdown students;
  final DayBreakdown staff;

  final List<ClassroomMovement> movements;
  final CenterSummary center;

  int get arrivingCount => movements.where((m) => m.isArriving).length;
  int get leavingCount => movements.where((m) => !m.isArriving).length;

  ClassroomProfile copyWith({ClassroomPhoto? photo, bool clearPhoto = false}) =>
      ClassroomProfile(
        summary: summary,
        photo: clearPhoto ? null : (photo ?? this.photo),
        students: students,
        staff: staff,
        movements: movements,
        center: center,
      );

  @override
  List<Object?> get props => [
    summary,
    photo,
    students,
    staff,
    movements,
    center,
  ];
}
