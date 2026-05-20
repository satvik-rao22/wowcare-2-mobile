import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../model/scheduling_models.dart';

part 'scheduling_state.dart';

class SchedulingCubit extends Cubit<SchedulingState> {
  SchedulingCubit() : super(SchedulingState.initial());

  /// Seed mock data so the UI renders before a real API is wired up.
  /// Replace this with a use-case-backed fetch when the backend lands.
  void load() {
    emit(state.copyWith(
      classrooms: _mockClassrooms,
      isLoading: false,
    ));
  }

  void setClassroomFilter(String? name) {
    emit(state.copyWith(classroomFilter: name));
  }

  void selectDay(DateTime day) {
    final DateTime normalized = DateTime(day.year, day.month, day.day);
    emit(state.copyWith(selectedDay: normalized));
  }

  // ---------------- Mock data ----------------

  static const List<ClassroomDaySchedule> _mockClassrooms = [
    ClassroomDaySchedule(
      classroomCode: 'CLS_BLUE_D',
      classroomName: '1-Blue-D',
      ratioStatus: ClassroomRatioStatus.underRatio,
      staff: [
        StaffScheduleEntry(
          staffName: 'Ana Biwalkar',
          scheduledHours: 45,
          availableHours: 55,
          startTime: '07:00 AM',
          endTime: '05:00 PM',
        ),
        StaffScheduleEntry(
          staffName: 'Ana Biwalkar',
          scheduledHours: 45,
          availableHours: 55,
          startTime: '07:00 AM',
          endTime: '05:00 PM',
        ),
        StaffScheduleEntry(
          staffName: 'Ana Biwalkar',
          scheduledHours: 45,
          availableHours: 55,
          startTime: '07:00 AM',
          endTime: '05:00 PM',
        ),
      ],
    ),
    ClassroomDaySchedule(
      classroomCode: 'CLS_YELLOW_C',
      classroomName: '2-Yellow-C',
      ratioStatus: ClassroomRatioStatus.inRatio,
      staff: [
        StaffScheduleEntry(
          staffName: 'Chaitanya Desai',
          scheduledHours: 45,
          availableHours: 55,
          startTime: '07:00 AM',
          endTime: '05:00 PM',
        ),
        StaffScheduleEntry(
          staffName: 'Spandana Shah',
          scheduledHours: 45,
          availableHours: 55,
          startTime: '07:00 AM',
          endTime: '05:00 PM',
        ),
      ],
    ),
    ClassroomDaySchedule(
      classroomCode: 'CLS_PURPLE_D',
      classroomName: '3-Purple-D',
      ratioStatus: ClassroomRatioStatus.underRatio,
    ),
    ClassroomDaySchedule(
      classroomCode: 'CLS_YELLOW_D',
      classroomName: '4-Yellow-D',
      ratioStatus: ClassroomRatioStatus.inRatio,
    ),
    ClassroomDaySchedule(
      classroomCode: 'CLS_GREEN_P',
      classroomName: '5-Green-P',
      ratioStatus: ClassroomRatioStatus.inRatio,
    ),
    ClassroomDaySchedule(
      classroomCode: 'CLS_PINK_P',
      classroomName: '6-Pink-P',
      ratioStatus: ClassroomRatioStatus.underRatio,
    ),
  ];
}
