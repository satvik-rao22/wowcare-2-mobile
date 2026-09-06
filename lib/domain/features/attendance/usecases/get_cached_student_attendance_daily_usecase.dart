import '../entities/student_attendance_daily.dart';
import '../repositories/attendance_repository.dart';

/// Wraps the optional cache lookup so [StudentAttendanceDailyCubit] doesn't
/// need to take [AttendanceRepository] directly just to type-check it against
/// [AttendanceRepositoryWithCache] — the cubit only ever used the repository
/// for this one capability-gated read.
class GetCachedStudentAttendanceDailyUseCase {
  GetCachedStudentAttendanceDailyUseCase(this._repository);

  final AttendanceRepository _repository;

  Future<StudentAttendanceDailyPage?> call(
    String attendanceDate, {
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  }) {
    if (_repository is! AttendanceRepositoryWithCache) return Future.value(null);
    return (_repository as AttendanceRepositoryWithCache)
        .loadCachedStudentAttendanceDaily(
          attendanceDate,
          classroomCodes: classroomCodes,
          tagCodes: tagCodes,
          search: search,
        );
  }
}
