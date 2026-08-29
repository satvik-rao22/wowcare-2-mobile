part of 'student_pickup_cubit.dart';

class StudentPickupState extends Equatable {
  const StudentPickupState({
    required this.mutationInProgress,
    this.errorMessage,
  });

  const StudentPickupState.initial()
      : mutationInProgress = false,
        errorMessage = null;

  final bool mutationInProgress;
  final String? errorMessage;

  StudentPickupState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
  }) {
    return StudentPickupState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [mutationInProgress, errorMessage];
}
