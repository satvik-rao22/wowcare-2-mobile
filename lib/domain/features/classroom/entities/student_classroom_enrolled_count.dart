import 'package:equatable/equatable.dart';

/// Active/upcoming/enrolled student counts for a classroom.
class StudentClassroomEnrolledCount extends Equatable {
  const StudentClassroomEnrolledCount({
    required this.activeCount,
    required this.upcomingCount,
    required this.enrolledCount,
  });

  final int activeCount;
  final int upcomingCount;
  final int enrolledCount;

  @override
  List<Object?> get props => [activeCount, upcomingCount, enrolledCount];
}
