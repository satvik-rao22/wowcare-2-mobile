import '../entities/student_attendance_custom.dart';
import '../repositories/attendance_repository.dart';

/// Wraps the optional cache lookup so [StudentAttendanceCustomCubit] doesn't
/// need to take [AttendanceRepository] directly just to type-check it against
/// [AttendanceRepositoryWithCache] — see [GetCachedStudentAttendanceDailyUseCase]
/// for the daily-view counterpart of this same fix.
class GetCachedStudentAttendanceCustomUseCase {
  GetCachedStudentAttendanceCustomUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StudentAttendanceCustomPage?> call(
    String fromAttendanceDate,
    String toAttendanceDate, {
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) {
    if (_repository is! AttendanceRepositoryWithCache) return Future.value(null);
    return (_repository as AttendanceRepositoryWithCache)
        .loadCachedStudentAttendanceCustom(
          fromAttendanceDate,
          toAttendanceDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        );
  }
}
