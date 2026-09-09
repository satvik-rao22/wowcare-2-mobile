part of 'staff_schedule_cubit.dart';

class StaffScheduleState extends Equatable {
  const StaffScheduleState({
    required this.mutationInProgress,
    this.errorMessage,
  });

  const StaffScheduleState.initial()
    : mutationInProgress = false,
      errorMessage = null;

  final bool mutationInProgress;
  final String? errorMessage;

  StaffScheduleState copyWith({
    bool? mutationInProgress,
    String? errorMessage,
  }) {
    return StaffScheduleState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [mutationInProgress, errorMessage];
}
