import 'package:equatable/equatable.dart';

import '../../../../domain/features/student_classroom/entities/student_classroom_item.dart';

class ClassroomStudentsState extends Equatable {
  const ClassroomStudentsState({
    required this.students,
    required this.isLoading,
    required this.isRefreshing,
    this.errorMessage,
    this.lastClassroomCode,
  });

  const ClassroomStudentsState.initial()
      : students = const [],
        isLoading = false,
        isRefreshing = false,
        errorMessage = null,
        lastClassroomCode = null;

  final List<StudentClassroomItem> students;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final String? lastClassroomCode;

  ClassroomStudentsState copyWith({
    List<StudentClassroomItem>? students,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    String? lastClassroomCode,
  }) {
    return ClassroomStudentsState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
      lastClassroomCode: lastClassroomCode ?? this.lastClassroomCode,
    );
  }

  @override
  List<Object?> get props => [
        students,
        isLoading,
        isRefreshing,
        errorMessage,
        lastClassroomCode,
      ];
}

