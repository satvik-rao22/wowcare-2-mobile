part of 'staff_profile_edit_cubit.dart';

class StaffProfileEditState extends Equatable {
  const StaffProfileEditState({
    required this.mutationInProgress,
    this.errorMessage,
  });

  const StaffProfileEditState.initial()
    : mutationInProgress = false,
      errorMessage = null;

  final bool mutationInProgress;
  final String? errorMessage;

  StaffProfileEditState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
  }) {
    return StaffProfileEditState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [mutationInProgress, errorMessage];
}
