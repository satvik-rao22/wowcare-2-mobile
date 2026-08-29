part of 'student_physician_cubit.dart';

class StudentPhysicianState extends Equatable {
  const StudentPhysicianState({
    required this.physicians,
    required this.isLoading,
    required this.mutationInProgress,
    this.errorMessage,
  });

  const StudentPhysicianState.initial()
      : physicians = const <StudentPhysician>[],
        isLoading = false,
        mutationInProgress = false,
        errorMessage = null;

  final List<StudentPhysician> physicians;
  final bool isLoading;
  final String? errorMessage;
  final bool mutationInProgress;

  StudentPhysicianState copyWith({
    List<StudentPhysician>? physicians,
    bool? isLoading,
    String? errorMessage,
    bool? mutationInProgress,
  }) {
    return StudentPhysicianState(
      physicians: physicians ?? this.physicians,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      mutationInProgress: mutationInProgress ?? this.mutationInProgress,
    );
  }

  @override
  List<Object?> get props => [
        physicians,
        isLoading,
        errorMessage,
        mutationInProgress,
      ];
}
