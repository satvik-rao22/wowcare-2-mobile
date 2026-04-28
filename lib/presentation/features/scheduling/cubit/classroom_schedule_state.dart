import 'package:equatable/equatable.dart';
import '../../../../domain/features/staff_scheduling/entities/staff_shift.dart';

abstract class ClassroomScheduleState extends Equatable {
  const ClassroomScheduleState();

  @override
  List<Object?> get props => [];
}

class ClassroomScheduleInitial extends ClassroomScheduleState {}

class ClassroomScheduleLoading extends ClassroomScheduleState {}

class ClassroomScheduleLoaded extends ClassroomScheduleState {
  final List<StaffShiftEntity> shifts;
  final String date;

  const ClassroomScheduleLoaded({required this.shifts, required this.date});

  @override
  List<Object?> get props => [shifts, date];
}

class ClassroomScheduleError extends ClassroomScheduleState {
  final String message;

  const ClassroomScheduleError(this.message);

  @override
  List<Object?> get props => [message];
}
