import '../entities/staff_attendance_daily.dart';
import '../repositories/attendance_repository.dart';

/// Use case to load the staff Sign-In form list for a given date range.
///
/// This uses the dedicated "sign-in form list" endpoint which internally
/// applies the appropriate sign-in/sign-out filters on the backend.
class GetStaffSignInFormListUseCase {
  GetStaffSignInFormListUseCase(this._repository);

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
    return _repository.getStaffSignInFormList(
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

