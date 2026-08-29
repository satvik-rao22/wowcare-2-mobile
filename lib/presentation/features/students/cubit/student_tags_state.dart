part of 'student_tags_cubit.dart';

class StudentTagsState extends Equatable {
  const StudentTagsState({
    required this.mutationInProgress,
    this.errorMessage,
  });

  const StudentTagsState.initial()
      : mutationInProgress = false,
        errorMessage = null;

  final bool mutationInProgress;
  final String? errorMessage;

  StudentTagsState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
  }) {
    return StudentTagsState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [mutationInProgress, errorMessage];
}
