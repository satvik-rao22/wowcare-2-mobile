import '../entities/student_attendance_custom.dart';
import '../repositories/attendance_repository.dart';

/// Use case to load the student Sign-Out form list for a given date range.
///
/// This uses the dedicated "sign-out form list" endpoint which internally
/// applies `signInAtFilter = NOT_NULL` and `signOutAtFilter = NULL`.
class GetStudentSignOutFormListUseCase {
  GetStudentSignOutFormListUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StudentAttendanceCustomPage> call({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) {
    return _repository.getStudentSignOutFormList(
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

