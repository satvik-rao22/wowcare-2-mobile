part of 'napping_students_cubit.dart';

abstract class NappingStudentsState {}

class NappingStudentsInitial extends NappingStudentsState {}

class NappingStudentsLoading extends NappingStudentsState {}

class NappingStudentsLoaded extends NappingStudentsState {
  final List<StudentEntity> nappingStudents;

  NappingStudentsLoaded(this.nappingStudents);
}

class NappingStudentsError extends NappingStudentsState {
  final String message;

  NappingStudentsError(this.message);
}
