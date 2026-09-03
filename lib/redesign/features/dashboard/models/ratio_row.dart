import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// One classroom's ratio, today (3A2 and 3S1).
///
/// Counts are written students-first, and there are two states only: In Ratio,
/// or short by [staffNeeded].
@immutable
class RatioRow extends Equatable {
  const RatioRow({
    required this.classroomName,
    required this.groupName,
    required this.students,
    required this.staff,
    required this.staffNeeded,
    this.enrolled,
    this.isCovering = false,
    this.coveringFrom,
  });

  final String classroomName;

  /// Toddler, Preschool: the age group under the name.
  final String groupName;

  /// How many of this classroom's students are in right now.
  final int students;
  final int staff;

  /// How many are on its roster. The staff ring counts [students] against
  /// this; null on a classroom the caller only knows today's count for.
  final int? enrolled;

  /// How many more staff the ratio wants. Zero means In Ratio.
  final int staffNeeded;

  /// A staff member's second classroom, which they only cover (3S1).
  final bool isCovering;
  final String? coveringFrom;

  bool get isInRatio => staffNeeded <= 0;

  @override
  List<Object?> get props => [
    classroomName,
    groupName,
    students,
    staff,
    staffNeeded,
    enrolled,
    isCovering,
    coveringFrom,
  ];
}
