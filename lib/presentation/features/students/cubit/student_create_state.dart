part of 'student_create_cubit.dart';

class StudentCreateState extends Equatable {
  const StudentCreateState({
    required this.mutationInProgress,
    this.errorMessage,
  });

  const StudentCreateState.initial()
      : mutationInProgress = false,
        errorMessage = null;

  final bool mutationInProgress;
  final String? errorMessage;

  StudentCreateState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
  }) {
    return StudentCreateState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [mutationInProgress, errorMessage];
}
