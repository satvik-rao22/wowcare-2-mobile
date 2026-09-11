part of 'student_health_cubit.dart';

class StudentHealthState extends Equatable {
  const StudentHealthState({
    required this.mutationInProgress,
    this.health,
    this.healthLoading = false,
    this.immunizations = const [],
    this.immunizationsLoading = false,
    this.errorMessage,
  });

  const StudentHealthState.initial()
    : mutationInProgress = false,
      health = null,
      healthLoading = false,
      immunizations = const [],
      immunizationsLoading = false,
      errorMessage = null;

  final bool mutationInProgress;

  /// This cubit serves two cards from separate instances: the Health card loads
  /// [health]; the Immunization card loads [immunizations]. Each instance uses
  /// only its half, so both live here without conflict.
  final StudentHealth? health;
  final bool healthLoading;
  final List<StudentImmunization> immunizations;
  final bool immunizationsLoading;
  final String? errorMessage;

  StudentHealthState copyWith({
    bool? mutationInProgress,
    StudentHealth? health,
    bool? healthLoading,
    List<StudentImmunization>? immunizations,
    bool? immunizationsLoading,
    String? errorMessage,
  }) {
    return StudentHealthState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      health: health ?? this.health,
      healthLoading: healthLoading ?? this.healthLoading,
      immunizations: immunizations ?? this.immunizations,
      immunizationsLoading: immunizationsLoading ?? this.immunizationsLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    mutationInProgress,
    health,
    healthLoading,
    immunizations,
    immunizationsLoading,
    errorMessage,
  ];
}
