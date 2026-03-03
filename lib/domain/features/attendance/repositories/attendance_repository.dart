import '../entities/student_attendance_daily.dart';
import '../entities/student_attendance_custom.dart';
import '../entities/staff_attendance_daily.dart';
import '../entities/staff_attendance_absent.dart';
import '../entities/student_attendance_absent_form.dart';

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

  /// Student Sign-In form list - students that can be signed in for a date range.
  Future<StudentAttendanceCustomPage> getStudentSignInFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  /// Student Sign-Out form list - students that can be signed out for a date range.
  Future<StudentAttendanceCustomPage> getStudentSignOutFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  /// Student Transfer form list - students that can be transferred for a date range.
  Future<StudentAttendanceCustomPage> getStudentTransferFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  /// Student Absent form list - students that can be marked absent for a date range.
  Future<StudentAttendanceAbsentFormPage> getStudentAbsentFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  /// Creates student absence records (Mark Absent).
  Future<String> markStudentsAbsent({
    required String staffCode,
    required List<String> studentCodes,
    required String absenceFromDate,
    required String absenceToDate,
    required String absenceReason,
    required Map<String, String> absenceNotes,
    required String classroomCode,
  });

  /// Student Absent toggle view - absent students for daily screen toggle.
  ///
  /// Response shape matches [StudentAttendanceAbsentFormPage].
  Future<StudentAttendanceAbsentFormPage> getStudentAttendanceAbsentToggleView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  Future<StaffAttendanceDailyPage> getStaffAttendanceDaily({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  Future<StaffAttendanceDailyPage> getStaffAttendanceCustom({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  Future<StaffAttendanceAbsentPage> getStaffAttendanceAbsent({
    required String fromAbsenceDate,
    required String toAbsenceDate,
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
