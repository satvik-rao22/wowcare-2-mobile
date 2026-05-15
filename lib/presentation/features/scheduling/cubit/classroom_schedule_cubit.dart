import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';
import 'classroom_schedule_state.dart';

class ClassroomScheduleCubit extends Cubit<ClassroomScheduleState> {
  final StaffSchedulingRepository _repository;

  ClassroomScheduleCubit(this._repository) : super(ClassroomScheduleInitial());

  Future<void> fetchSchedules({
    required String classroomCode,
    required String date,
  }) async {
    emit(ClassroomScheduleLoading());
    try {
      // Fetching for a single day based on the UI requirement
      final shifts = await _repository.getStaffShifts(
        classroomCode: classroomCode,
        dateFrom: date,
        dateTo: date,
      );
      
      emit(
        ClassroomScheduleLoaded(
          shifts: shifts,
          date: date,
        ),
      );
    } catch (e) {
      emit(ClassroomScheduleError(e.toString()));
    }
  }
}
