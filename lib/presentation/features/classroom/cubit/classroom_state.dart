part of 'classroom_cubit.dart';

class ClassroomState extends Equatable {
  const ClassroomState({
    required this.classrooms,
    required this.isLoading,
    required this.errorMessage,
  });

  const ClassroomState.initial()
      : classrooms = const [],
        isLoading = false,
        errorMessage = null;

  final List<Classroom> classrooms;
  final bool isLoading;
  final String? errorMessage;

  ClassroomState copyWith({
    List<Classroom>? classrooms,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ClassroomState(
      classrooms: classrooms ?? this.classrooms,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [classrooms, isLoading, errorMessage];
}

