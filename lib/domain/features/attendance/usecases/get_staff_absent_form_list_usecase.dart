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
    // This uses the same repository method as the staff absent view
    // but is conceptually used for the "mark absent" form.
    return _repository.getStaffAttendanceAbsent(
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

