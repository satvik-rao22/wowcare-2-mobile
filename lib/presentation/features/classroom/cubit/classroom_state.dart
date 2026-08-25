part of 'classroom_cubit.dart';

class ClassroomState extends Equatable {
  const ClassroomState({
    required this.classrooms,
    required this.isLoading,
    required this.errorMessage,
    required this.onlyTypeClassroom,
    required this.applyAttendanceStaffScope,
  });

  const ClassroomState.initial()
    : classrooms = const [],
      isLoading = false,
      errorMessage = null,
      onlyTypeClassroom = true,
      applyAttendanceStaffScope = false;

  final List<Classroom> classrooms;
  final bool isLoading;
  final String? errorMessage;

  /// Tracks whether the last load used type=CLASSROOM filter.
  final bool onlyTypeClassroom;

  /// Tracks whether the last load applied staff classroom scoping.
  final bool applyAttendanceStaffScope;

  ClassroomState copyWith({
    List<Classroom>? classrooms,
    bool? isLoading,
    String? errorMessage,
    bool? onlyTypeClassroom,
    bool? applyAttendanceStaffScope,
  }) {
    return ClassroomState(
      classrooms: classrooms ?? this.classrooms,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      onlyTypeClassroom: onlyTypeClassroom ?? this.onlyTypeClassroom,
      applyAttendanceStaffScope:
          applyAttendanceStaffScope ?? this.applyAttendanceStaffScope,
    );
  }

  @override
  List<Object?> get props => [
    classrooms,
    isLoading,
    errorMessage,
    onlyTypeClassroom,
    applyAttendanceStaffScope,
  ];
}
