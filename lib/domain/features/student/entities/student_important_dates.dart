import 'package:equatable/equatable.dart';

/// Domain entity representing important dates for a student.
class StudentImportantDates extends Equatable {
  const StudentImportantDates({
    this.enrollDate,
    this.schoolStartDate,
    this.currentClassroomStartDate,
    this.upcomingMoveDate,
    this.schoolLeavingDate,
  });

  final DateTime? enrollDate;
  final DateTime? schoolStartDate;
  final DateTime? currentClassroomStartDate;
  final DateTime? upcomingMoveDate;
  final DateTime? schoolLeavingDate;

  @override
  List<Object?> get props => [
    enrollDate,
    schoolStartDate,
    currentClassroomStartDate,
    upcomingMoveDate,
    schoolLeavingDate,
  ];
}
