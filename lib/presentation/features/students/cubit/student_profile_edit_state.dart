part of 'student_profile_edit_cubit.dart';

class StudentProfileEditState extends Equatable {
  const StudentProfileEditState({
    required this.mutationInProgress,
    this.errorMessage,
  });

  const StudentProfileEditState.initial()
      : mutationInProgress = false,
        errorMessage = null;

  final bool mutationInProgress;
  final String? errorMessage;

  StudentProfileEditState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
  }) {
    return StudentProfileEditState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [mutationInProgress, errorMessage];
}
