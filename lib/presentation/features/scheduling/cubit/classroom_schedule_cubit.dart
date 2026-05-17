import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';

import '../../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository_impl.dart';
import 'classroom_schedule_state.dart';

class ClassroomScheduleCubit extends Cubit<ClassroomScheduleState> {
  final StaffSchedulingRepository _repository;

  ClassroomScheduleCubit(this._repository) : super(ClassroomScheduleInitial());

  Future<void> fetchSchedules({
    required String classroomCode,
    required String date,
    required String schoolCode,
  }) async {
    emit(ClassroomScheduleLoading());

    try {
      /// =========================
      /// FETCH CLASSROOMS
      /// =========================

      final classroomResponse = await _repository.getAllClassrooms(schoolCode);

      /// =========================
      /// FETCH TIMEZONE
      /// =========================

      final timezone = await (_repository as StaffSchedulingRepositoryImpl)
          .fetchSchoolTimeZone(schoolCode);

      print('School Timezone => $timezone');

      /// =========================
      /// FETCH SHIFTS
      /// =========================

      final shifts = await _repository.getStaffShifts(
        classroomCode: classroomCode,
        dateFrom: date,
        dateTo: date,
      );

      final classrooms = classroomResponse.map((e) {
        return ClassroomEntity(
          classroomCode: e['classroomCode'] ?? '',
          name: e['name'] ?? '',
          schoolCode: e['schoolCode'] ?? '',
        );
      }).toList();

      emit(
        ClassroomScheduleLoaded(
          shifts: shifts,
          classrooms: classrooms,
          date: date,
        ),
      );
    } catch (e) {
      emit(ClassroomScheduleError(e.toString()));
    }
  }
}
