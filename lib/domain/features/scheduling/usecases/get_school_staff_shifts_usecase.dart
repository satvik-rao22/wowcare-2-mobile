import '../entities/staff_shift.dart';
import '../repositories/staff_shift_repository.dart';

/// School-wide shifts loader for the classroom scheduling table — calls
/// `GET /api/v1/staff-shifts?schoolCode&organizationCode&dateFrom&dateTo`
/// with optional `classroomCode` when the week-view classroom filter is set.
class GetSchoolStaffShiftsUseCase {
  GetSchoolStaffShiftsUseCase(this._repository);

  final StaffShiftRepository _repository;

  Future<List<StaffShift>> call({
    required String schoolCode,
    required String organizationCode,
    required DateTime dateFrom,
    required DateTime dateTo,
    String? classroomCode,
  }) {
    return _repository.getSchoolStaffShifts(
      schoolCode: schoolCode,
      organizationCode: organizationCode,
      dateFrom: dateFrom,
      dateTo: dateTo,
      classroomCode: classroomCode,
    );
  }
}
