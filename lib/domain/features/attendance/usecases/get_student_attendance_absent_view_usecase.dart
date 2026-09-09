import '../entities/student_attendance_absent_view_response.dart';
import '../repositories/attendance_repository.dart';

/// Loads the student absent view list (classroom filter + allowed scope applied).
///
/// A thin application-service seam so the presentation layer never talks to
/// [AttendanceRepository] (or the network) directly. Behaviour is an exact
/// pass-through: the raw response is returned as-is and any thrown error is
/// propagated unchanged.
class GetStudentAttendanceAbsentViewUseCase {
  const GetStudentAttendanceAbsentViewUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StudentAttendanceAbsentViewResponse?> call({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
  }) {
    return _repository.getStudentAttendanceAbsentView(
      fromAbsenceDate: fromAbsenceDate,
      toAbsenceDate: toAbsenceDate,
      classroomCodes: classroomCodes,
      tagCodes: tagCodes,
      search: search,
      page: page,
      size: size,
      sort: sort,
    );
  }
}
