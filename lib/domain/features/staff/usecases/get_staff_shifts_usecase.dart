import '../../scheduling/repositories/staff_scheduling_repository.dart';
import '../entities/staff_shift.dart';

class GetStaffShiftsUseCase {
  GetStaffShiftsUseCase(this._repository);

  final StaffSchedulingRepository _repository;

  Future<StaffShiftDaySummary> call({
    required String organizationCode,
    required String schoolCode,
    required String staffCode,
    required DateTime date,
    String? classroomCode,
    List<String>? shiftStatus,
  }) {
    return _repository.getStaffShiftsForDay(
      organizationCode: organizationCode,
      schoolCode: schoolCode,
      staffCode: staffCode,
      date: date,
      classroomCode: classroomCode,
      shiftStatus: shiftStatus,
    );
  }
}
