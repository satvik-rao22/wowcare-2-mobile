import 'package:equatable/equatable.dart';

import '../../../../domain/features/student_classroom/entities/student_classroom_item.dart';

class ClassroomStudentsState extends Equatable {
  const ClassroomStudentsState({
    required this.students,
    required this.isLoading,
    required this.isRefreshing,
    this.errorMessage,
    this.lastClassroomCode,
    this.nappingStudentCodes = const <String>{},
    this.napCodesLoading = false,
  });

  const ClassroomStudentsState.initial()
    : students = const [],
      isLoading = false,
      isRefreshing = false,
      errorMessage = null,
      lastClassroomCode = null,
      nappingStudentCodes = const <String>{},
      napCodesLoading = false;

  final List<StudentClassroomItem> students;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final String? lastClassroomCode;

  /// Student codes currently on a nap, per the classroom's nap-start
  /// tracking — drives the napping filter/toggle on the Students tab.
  final Set<String> nappingStudentCodes;
  final bool napCodesLoading;

  ClassroomStudentsState copyWith({
    List<StudentClassroomItem>? students,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    String? lastClassroomCode,
    Set<String>? nappingStudentCodes,
    bool? napCodesLoading,
  }) {
    return ClassroomStudentsState(
      students: students ?? this.students,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
      lastClassroomCode: lastClassroomCode ?? this.lastClassroomCode,
      nappingStudentCodes: nappingStudentCodes ?? this.nappingStudentCodes,
      napCodesLoading: napCodesLoading ?? this.napCodesLoading,
    );
  }

  @override
  List<Object?> get props => [
    students,
    isLoading,
    isRefreshing,
    errorMessage,
    lastClassroomCode,
    nappingStudentCodes,
    napCodesLoading,
  ];
}
