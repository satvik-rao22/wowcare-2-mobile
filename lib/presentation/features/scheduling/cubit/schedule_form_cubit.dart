import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/features/staff_scheduling/usecases/save_schedule_usecase.dart';
import 'schedule_form_state.dart';

class ScheduleFormCubit extends Cubit<ScheduleFormState> {
  final SaveScheduleUseCase _saveScheduleUseCase;

  ScheduleFormCubit(this._saveScheduleUseCase) : super(ScheduleFormInitial());

  Future<void> saveSchedule({String? id, required Map<String, dynamic> data}) async {
    emit(ScheduleFormSubmitting());
    try {
      await _saveScheduleUseCase(id: id, data: data);
      emit(ScheduleFormSuccess());
    } catch (e) {
      emit(ScheduleFormError(e.toString()));
    }
  }
}
