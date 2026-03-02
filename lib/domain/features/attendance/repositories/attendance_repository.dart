import '../entities/student_attendance_daily.dart';
import '../entities/student_attendance_custom.dart';

abstract class AttendanceRepository {
  Future<StudentAttendanceDailyPage> getStudentAttendanceDaily({
    required String attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  Future<StudentAttendanceCustomPage> getStudentAttendanceCustom({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });
}

/// Optional mixin-style interface for repositories that expose cached data.
abstract class AttendanceRepositoryWithCache {
  Future<StudentAttendanceDailyPage?> loadCachedStudentAttendanceDaily(
    String attendanceDate, {
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  });

  Future<StudentAttendanceCustomPage?> loadCachedStudentAttendanceCustom(
    String fromAttendanceDate,
    String toAttendanceDate, {
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
  });
}
