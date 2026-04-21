import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/features/staff_scheduling/repositories/staff_scheduling_repository.dart';
import 'classroom_schedule_state.dart';

class ClassroomScheduleCubit extends Cubit<ClassroomScheduleState> {
  final StaffSchedulingRepository _repository;

  ClassroomScheduleCubit(this._repository) : super(ClassroomScheduleInitial());

  Future<void> fetchSchedules() async {
    emit(ClassroomScheduleLoading());
    try {
      final schedules = await _repository.getClassroomSchedules();
      emit(
        ClassroomScheduleLoaded(
          entries: schedules,
          date: 'Dec 27', // This could be passed as a parameter
        ),
      );
    } catch (e) {
      emit(ClassroomScheduleError(e.toString()));
    }
  }
}
