part of 'student_health_cubit.dart';

class StudentHealthState extends Equatable {
  const StudentHealthState({
    required this.mutationInProgress,
    this.errorMessage,
  });

  const StudentHealthState.initial()
      : mutationInProgress = false,
        errorMessage = null;

  final bool mutationInProgress;
  final String? errorMessage;

  StudentHealthState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
  }) {
    return StudentHealthState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [mutationInProgress, errorMessage];
}
