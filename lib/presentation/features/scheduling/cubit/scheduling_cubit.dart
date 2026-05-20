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

  void shiftSelectedDay(int deltaDays) {
    selectDay(state.selectedDay.add(Duration(days: deltaDays)));
  }

  void setViewMode(SchedulingViewMode mode) {
    if (state.viewMode == mode) return;
    emit(state.copyWith(viewMode: mode));
  }

  // ---------------- Mock data ----------------

  // 24 slots covering a workday-ish window. Each slot is treated as ~30 min.
  static const List<TimeSlotStatus> _classroomSlotsBlueD = [
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.underRatio, TimeSlotStatus.underRatio,
    TimeSlotStatus.underRatio, TimeSlotStatus.underRatio, TimeSlotStatus.underRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.overRatio, TimeSlotStatus.overRatio,
    TimeSlotStatus.empty, TimeSlotStatus.empty, TimeSlotStatus.empty,
  ];

  static const List<TimeSlotStatus> _staffSlotsA = [
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.underRatio, TimeSlotStatus.underRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.empty, TimeSlotStatus.empty, TimeSlotStatus.empty,
  ];

  static const List<TimeSlotStatus> _staffSlotsB = [
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.underRatio, TimeSlotStatus.underRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.inRatio, TimeSlotStatus.inRatio,
    TimeSlotStatus.inRatio, TimeSlotStatus.empty, TimeSlotStatus.empty,
    TimeSlotStatus.empty, TimeSlotStatus.empty, TimeSlotStatus.empty,
  ];

  static const List<ClassroomDaySchedule> _mockClassrooms = [
    ClassroomDaySchedule(
      classroomCode: 'CLS_BLUE_D',
      classroomName: '1-Blue-D',
      ratioStatus: ClassroomRatioStatus.underRatio,
      daySlots: _classroomSlotsBlueD,
      staff: [
        StaffScheduleEntry(
          staffName: 'Ana Biwalkar',
          scheduledHours: 45,
          availableHours: 55,
          startTime: '07:00 AM',
          endTime: '05:00 PM',
          daySlots: _staffSlotsA,
        ),
        StaffScheduleEntry(
          staffName: 'Ana Biwalkar',
          scheduledHours: 45,
          availableHours: 55,
          startTime: '07:00 AM',
          endTime: '05:00 PM',
          daySlots: _staffSlotsB,
        ),
        StaffScheduleEntry(
          staffName: 'Ana Biwalkar',
          scheduledHours: 45,
          availableHours: 55,
          startTime: '07:00 AM',
          endTime: '05:00 PM',
          daySlots: _staffSlotsA,
        ),
      ],
    ),
    ClassroomDaySchedule(
      classroomCode: 'CLS_YELLOW_C',
      classroomName: '2-Yellow-C',
      ratioStatus: ClassroomRatioStatus.inRatio,
      daySlots: _staffSlotsB,
      staff: [
        StaffScheduleEntry(
          staffName: 'Chaitanya Desai',
          scheduledHours: 45,
          availableHours: 55,
          startTime: '07:00 AM',
          endTime: '05:00 PM',
          daySlots: _staffSlotsA,
        ),
        StaffScheduleEntry(
          staffName: 'Spandana Shah',
          scheduledHours: 45,
          availableHours: 55,
          startTime: '07:00 AM',
          endTime: '05:00 PM',
          daySlots: _staffSlotsB,
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
