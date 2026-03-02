import '../entities/staff_attendance_daily.dart';
import '../repositories/attendance_repository.dart';

class GetStaffAttendanceDailyUseCase {
  GetStaffAttendanceDailyUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StaffAttendanceDailyPage> call({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) {
    return _repository.getStaffAttendanceDaily(
      fromAttendanceDate: fromAttendanceDate,
      toAttendanceDate: toAttendanceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
    );
  }
}

