import '../entities/staff_attendance_daily.dart';
import '../repositories/attendance_repository.dart';

/// Use case to load the staff Transfer form list for a given date range.
class GetStaffTransferFormListUseCase {
  GetStaffTransferFormListUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StaffAttendanceDailyPage> call({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) {
    // For transfer form, backend uses absence-style date params and
    // a dedicated transfer endpoint, but the response content matches
    // the staff attendance list shape.
    return _repository.getStaffTransferFormList(
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

