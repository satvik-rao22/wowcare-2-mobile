part of 'classroom_cubit.dart';

class ClassroomState extends Equatable {
  const ClassroomState({
    required this.classrooms,
    required this.isLoading,
    required this.errorMessage,
    required this.onlyTypeClassroom,
  });

  const ClassroomState.initial()
      : classrooms = const [],
        isLoading = false,
        errorMessage = null,
        onlyTypeClassroom = true;

  final List<Classroom> classrooms;
  final bool isLoading;
  final String? errorMessage;
  /// Tracks whether the last load used type=CLASSROOM filter.
  final bool onlyTypeClassroom;

  ClassroomState copyWith({
    List<Classroom>? classrooms,
    bool? isLoading,
    String? errorMessage,
    bool? onlyTypeClassroom,
  }) {
    return ClassroomState(
      classrooms: classrooms ?? this.classrooms,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      onlyTypeClassroom: onlyTypeClassroom ?? this.onlyTypeClassroom,
    );
  }

  @override
  List<Object?> get props => [classrooms, isLoading, errorMessage, onlyTypeClassroom];
}

