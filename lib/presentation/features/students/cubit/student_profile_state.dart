part of 'student_profile_cubit.dart';

class StudentProfileState extends Equatable {
  const StudentProfileState({
    required this.mutationInProgress,
    this.errorMessage,
  });

  const StudentProfileState.initial()
      : mutationInProgress = false,
        errorMessage = null;

  final bool mutationInProgress;
  final String? errorMessage;

  StudentProfileState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
  }) {
    return StudentProfileState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [mutationInProgress, errorMessage];
}
