import '../entities/student_attendance_custom.dart';
import '../repositories/attendance_repository.dart';

/// Use case to load the student Transfer form list for a given date range.
///
/// Uses the dedicated "transfer form list" endpoint.
class GetStudentTransferFormListUseCase {
  GetStudentTransferFormListUseCase(this._repository);

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
    return _repository.getStudentTransferFormList(
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
