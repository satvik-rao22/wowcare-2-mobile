part of 'student_guardian_cubit.dart';

class StudentGuardianState extends Equatable {
  const StudentGuardianState({
    required this.mutationInProgress,
    this.guardians = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  const StudentGuardianState.initial()
    : mutationInProgress = false,
      guardians = const [],
      isLoading = false,
      errorMessage = null;

  final bool mutationInProgress;

  /// The cubit owns the guardian list (single source of truth for the card).
  final List<StudentGuardian> guardians;
  final bool isLoading;
  final String? errorMessage;

  StudentGuardianState copyWith({
    bool? mutationInProgress,
    List<StudentGuardian>? guardians,
    bool? isLoading,
    String? errorMessage,
  }) {
    return StudentGuardianState(
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
      guardians: guardians ?? this.guardians,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    mutationInProgress,
    guardians,
    isLoading,
    errorMessage,
  ];
}
