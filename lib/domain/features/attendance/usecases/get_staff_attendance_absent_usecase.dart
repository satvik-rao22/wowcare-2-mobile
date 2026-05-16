import '../entities/staff_attendance_absent.dart';
import '../repositories/attendance_repository.dart';

class GetStaffAttendanceAbsentUseCase {
  GetStaffAttendanceAbsentUseCase(this._repository);

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
