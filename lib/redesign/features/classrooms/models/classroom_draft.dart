import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// A new classroom, as the create form fills it in.
///
/// The four fields the classroom record needs: name, the two age bounds in
/// whole months, capacity, and how many students one staff member may
/// supervise. Nothing else is required to create one on the web.
@immutable
class ClassroomDraft extends Equatable {
  const ClassroomDraft({
    this.name = '',
    this.ageFromMonths,
    this.ageToMonths,
    this.capacity,
    this.studentsPerStaff,
  });

  final String name;

  /// Inclusive bounds in whole months, as `Classroom.minAgeMonths` carries
  /// them. Null means that side is not enforced.
  final int? ageFromMonths;
  final int? ageToMonths;

  final int? capacity;

  /// `studentsTeacherRatio`. The ratio the app then shows as counts.
  final int? studentsPerStaff;

  ClassroomDraft copyWith({
    String? name,
    int? ageFromMonths,
    int? ageToMonths,
    int? capacity,
    int? studentsPerStaff,
    bool clearAgeFrom = false,
    bool clearAgeTo = false,
    bool clearCapacity = false,
    bool clearStudentsPerStaff = false,
  }) => ClassroomDraft(
    name: name ?? this.name,
    ageFromMonths: clearAgeFrom ? null : (ageFromMonths ?? this.ageFromMonths),
    ageToMonths: clearAgeTo ? null : (ageToMonths ?? this.ageToMonths),
    capacity: clearCapacity ? null : (capacity ?? this.capacity),
    studentsPerStaff: clearStudentsPerStaff
        ? null
        : (studentsPerStaff ?? this.studentsPerStaff),
  );

  @override
  List<Object?> get props => [
    name,
    ageFromMonths,
    ageToMonths,
    capacity,
    studentsPerStaff,
  ];
}
