import '../entities/student_attendance_absent_form.dart';
import '../repositories/attendance_repository.dart';

/// Use case to load the student Absent form list for a given date range.
class GetStudentAbsentFormListUseCase {
  GetStudentAbsentFormListUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StudentAttendanceAbsentFormPage> call({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
  }) {
    return _repository.getStudentAbsentFormList(
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

