import 'package:equatable/equatable.dart';

import '../../../../domain/features/classroom/entities/classroom.dart';
import '../../../../domain/features/student/entities/student.dart';

class AssignStudentConfirmationState extends Equatable {
  const AssignStudentConfirmationState({
    this.selectedStudents = const {},
    this.isSubmitting = false,
    this.targetClassroom,
  });

  final Set<Student> selectedStudents;
  final bool isSubmitting;

  /// The target classroom (with age bounds), resolved once on init. Null
  /// while loading or if the fetch fails — either way the age-range warning
  /// is simply skipped.
  final Classroom? targetClassroom;

  AssignStudentConfirmationState copyWith({
    Set<Student>? selectedStudents,
    bool? isSubmitting,
    Classroom? targetClassroom,
  }) {
    return AssignStudentConfirmationState(
      selectedStudents: selectedStudents ?? this.selectedStudents,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      targetClassroom: targetClassroom ?? this.targetClassroom,
    );
  }

  @override
  List<Object?> get props => [selectedStudents, isSubmitting, targetClassroom];
}
