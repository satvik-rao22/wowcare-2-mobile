part of 'student_physical_exam_cubit.dart';

class StudentPhysicalExamState extends Equatable {
  const StudentPhysicalExamState({
    required this.mutationInProgress,
    this.errorMessage,
  });

  const StudentPhysicalExamState.initial()
      : mutationInProgress = false,
        errorMessage = null;

  final bool mutationInProgress;
  final String? errorMessage;

  StudentPhysicalExamState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
  }) {
    return StudentPhysicalExamState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [mutationInProgress, errorMessage];
}
