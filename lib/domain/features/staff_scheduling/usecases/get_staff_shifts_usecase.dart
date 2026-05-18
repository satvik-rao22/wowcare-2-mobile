import '../entities/staff_shift.dart';
import '../repositories/staff_scheduling_repository.dart';

class GetStaffShiftsUseCase {
  final StaffSchedulingRepository _repository;

  GetStaffShiftsUseCase(this._repository);

  Future<List<StaffShiftEntity>> call({
    required String schoolCode,
    required String organizationCode,
    String? classroomCode,
    required String dateFrom,
    required String dateTo,
    String? shiftStatus,
    int page = 0,
    int size = 50,
  }) {
    return _repository.getStaffShifts(
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      classroomCode: classroomCode,
      dateFrom: dateFrom,
      dateTo: dateTo,
      shiftStatus: shiftStatus,
      page: page,
      size: size,
    );
  }
}

