import 'package:equatable/equatable.dart';

import '../../../../domain/features/staff_scheduling/entities/staff_shift.dart';

class ClassroomEntity extends Equatable {
  final String classroomCode;
  final String name;
  final String schoolCode;

  const ClassroomEntity({
    required this.classroomCode,
    required this.name,
    required this.schoolCode,
  });

  @override
  List<Object?> get props => [classroomCode, name, schoolCode];
}

abstract class ClassroomScheduleState extends Equatable {
  const ClassroomScheduleState();

  @override
  List<Object?> get props => [];
}

class ClassroomScheduleInitial extends ClassroomScheduleState {}

class ClassroomScheduleLoading extends ClassroomScheduleState {}

class ClassroomScheduleLoaded extends ClassroomScheduleState {
  final List<StaffShiftEntity> shifts;

  final List<ClassroomEntity> classrooms;

  final String date;

  const ClassroomScheduleLoaded({
    required this.shifts,
    required this.classrooms,
    required this.date,
  });

  @override
  List<Object?> get props => [shifts, classrooms, date];
}

class ClassroomScheduleError extends ClassroomScheduleState {
  final String message;

  const ClassroomScheduleError(this.message);

  @override
  List<Object?> get props => [message];
}
