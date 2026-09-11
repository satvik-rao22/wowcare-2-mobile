import '../entities/staff_schedule_entry.dart';
import '../repositories/staff_repository.dart';

class UpdateStaffSchedulesUseCase {
  UpdateStaffSchedulesUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String staffCode,
    required List<StaffWorkScheduleEntry> workSchedules,
    required List<StaffBreakScheduleEntry> breakSchedules,
  }) {
    return _repository.updateStaffSchedules(
      staffCode: staffCode,
      workSchedules: workSchedules,
      breakSchedules: breakSchedules,
    );
  }
}
