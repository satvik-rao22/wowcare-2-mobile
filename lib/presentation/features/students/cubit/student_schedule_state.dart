part of 'student_schedule_cubit.dart';

class StudentScheduleState extends Equatable {
  const StudentScheduleState({
    this.schedule = const {},
    this.copyToAllDays = false,
    this.schoolMinutesByDay = const {},
    this.hasInitialSchedule = false,
  });

  const StudentScheduleState.initial()
      : schedule = const {},
        copyToAllDays = false,
        schoolMinutesByDay = const {},
        hasInitialSchedule = false;

  /// day (display name) → {'start': TimeOfDay, 'end': TimeOfDay}.
  final Map<String, Map<String, TimeOfDay>> schedule;
  final bool copyToAllDays;

  /// API day key (e.g. MONDAY) → (startMinutes, endMinutes) working-hours bounds.
  final Map<String, (int, int)> schoolMinutesByDay;
  final bool hasInitialSchedule;

  StudentScheduleState copyWith({
    Map<String, Map<String, TimeOfDay>>? schedule,
    bool? copyToAllDays,
    Map<String, (int, int)>? schoolMinutesByDay,
    bool? hasInitialSchedule,
  }) {
    return StudentScheduleState(
      schedule: schedule ?? this.schedule,
      copyToAllDays: copyToAllDays ?? this.copyToAllDays,
      schoolMinutesByDay: schoolMinutesByDay ?? this.schoolMinutesByDay,
      hasInitialSchedule: hasInitialSchedule ?? this.hasInitialSchedule,
    );
  }

  @override
  List<Object?> get props =>
      [schedule, copyToAllDays, schoolMinutesByDay, hasInitialSchedule];
}
