part of 'student_guardian_cubit.dart';

class StudentGuardianState extends Equatable {
  const StudentGuardianState({
    required this.mutationInProgress,
    this.errorMessage,
  });

  const StudentGuardianState.initial()
      : mutationInProgress = false,
        errorMessage = null;

  final bool mutationInProgress;
  final String? errorMessage;

  StudentGuardianState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
  }) {
    return StudentGuardianState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [mutationInProgress, errorMessage];
}
