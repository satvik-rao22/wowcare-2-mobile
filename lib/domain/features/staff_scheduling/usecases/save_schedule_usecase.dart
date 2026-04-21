import '../repositories/staff_scheduling_repository.dart';

class SaveScheduleUseCase {
  final StaffSchedulingRepository _repository;

  SaveScheduleUseCase(this._repository);

  Future<void> call({String? id, required Map<String, dynamic> data}) async {
    if (id != null) {
      return await _repository.editSchedule(id, data);
    } else {
      return await _repository.addSchedule(data);
    }
  }
}
