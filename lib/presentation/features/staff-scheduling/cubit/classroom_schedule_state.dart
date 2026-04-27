import '../../../../domain/features/staff_scheduling/entities/schedule_entry.dart';

abstract class ClassroomScheduleState {}

class ClassroomScheduleInitial extends ClassroomScheduleState {}

class ClassroomScheduleLoading extends ClassroomScheduleState {}

class ClassroomScheduleLoaded extends ClassroomScheduleState {
  final List<ScheduleEntryEntity> entries;
  final String date;

  ClassroomScheduleLoaded({required this.entries, required this.date});
}

class ClassroomScheduleError extends ClassroomScheduleState {
  final String message;
  ClassroomScheduleError(this.message);
}
