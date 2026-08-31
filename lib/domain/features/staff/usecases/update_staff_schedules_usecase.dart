import '../repositories/staff_repository.dart';

class UpdateStaffSchedulesUseCase {
  UpdateStaffSchedulesUseCase(this._repository);

  final StaffRepository _repository;

  Future<String> call({
    required String staffCode,
    required List<Map<String, dynamic>> workSchedules,
    required List<Map<String, dynamic>> breakSchedules,
  }) {
    return _repository.updateStaffSchedules(
      staffCode: staffCode,
      workSchedules: workSchedules,
      breakSchedules: breakSchedules,
    );
  }
}
