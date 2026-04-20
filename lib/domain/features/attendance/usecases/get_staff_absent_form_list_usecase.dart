import '../entities/staff_attendance_absent.dart';
import '../repositories/attendance_repository.dart';

/// Use case to load the staff Absent form list for a given date range.
class GetStaffAbsentFormListUseCase {
  GetStaffAbsentFormListUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StaffAttendanceAbsentPage> call({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) {
    return _repository.getStaffAbsentFormList(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
    );
  }
}

