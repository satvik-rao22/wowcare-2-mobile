import '../entities/av2_staff_summary.dart';
import '../repositories/attendance_v2_repository.dart';

/// Loads the school's active staff for the admin "switch staff" picker.
class GetStaffListUseCase {
  GetStaffListUseCase(this._repository);

  final AttendanceV2Repository _repository;

  Future<List<Av2StaffSummary>> call() => _repository.getStaff();
}
