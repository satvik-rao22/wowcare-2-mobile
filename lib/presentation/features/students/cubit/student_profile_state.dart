part of 'student_profile_cubit.dart';

class StudentProfileState extends Equatable {
  const StudentProfileState({
    required this.mutationInProgress,
    this.health,
    this.healthLoading = false,
    this.errorMessage,
  });

  const StudentProfileState.initial()
      : mutationInProgress = false,
        health = null,
        healthLoading = false,
        errorMessage = null;

  final bool mutationInProgress;

  /// The header health record (drives the allergy/medication/diet/photo icons).
  final StudentHealth? health;
  final bool healthLoading;
  final String? errorMessage;

  StudentProfileState copyWith({
    bool? mutationInProgress,
    StudentHealth? health,
    bool? healthLoading,
    String? errorMessage,
  }) {
    return StudentProfileState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      health: health ?? this.health,
      healthLoading: healthLoading ?? this.healthLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [mutationInProgress, health, healthLoading, errorMessage];
}
