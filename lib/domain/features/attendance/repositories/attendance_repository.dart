import '../entities/student_attendance_daily.dart';
import '../entities/student_attendance_custom.dart';
import '../entities/staff_attendance_daily.dart';
import '../entities/staff_attendance_absent.dart';
import '../entities/student_attendance_absent_form.dart';
import '../entities/student_attendance_expected_summary.dart';

abstract class AttendanceRepository {
  Future<StudentAttendanceDailyPage> getStudentAttendanceDaily({
    required String attendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  /// Expected attendance summary for the daily "Expected Students" card.
  Future<StudentAttendanceExpectedSummary>
      getStudentAttendanceExpectedSummary();

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

  /// Creates staff absence records (Mark Absent).
  Future<String> markStaffAbsent({
    required String staffCode,
    required List<String> staffCodes,
    required String absenceFromDate,
    required String absenceToDate,
    required String absenceReason,
    required String absenceType,
    required Map<String, String> absenceNotes,
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

  /// Staff expected attendance summary for the daily "Expected Staff" card.
  Future<StudentAttendanceExpectedSummary>
      getStaffAttendanceExpectedSummary();

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

  /// Staff Absent form list - staff that can be marked absent for a date range.
  ///
  /// Backend endpoint: `/api/v1/staff-attendance/absent/form/list`.
  /// Response shape matches [StaffAttendanceAbsentPage].
  Future<StaffAttendanceAbsentPage> getStaffAbsentFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  /// Staff Absent toggle view - absent staff for daily screen toggle.
  ///
  /// Response shape matches [StaffAttendanceAbsentPage].
  Future<StaffAttendanceAbsentPage> getStaffAttendanceAbsentToggleView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  /// Staff Sign-In form list - staff that can be signed in for a date range.
  Future<StaffAttendanceDailyPage> getStaffSignInFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  /// Staff Sign-Out form list - staff that can be signed out for a date range.
  Future<StaffAttendanceDailyPage> getStaffSignOutFormList({
    required String fromAttendanceDate,
    required String toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  /// Staff Transfer form list - staff that can be transferred for a date range.
  Future<StaffAttendanceDailyPage> getStaffTransferFormList({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page,
    int size,
  });

  /// Current-day sign-in status for a single staff member.
  ///
  /// Returns a status string such as `SIGNED_IN` or `ABSENT`, or `null`
  /// if the backend did not return a status for this code.
  Future<String?> getStaffTodaySignInStatus(String staffCode);

  /// Current-day sign-in status for a single student.
  ///
  /// Returns a status string such as `SIGNED_IN` or `ABSENT`, or `null`
  /// if the backend did not return a status for this code.
  Future<String?> getStudentTodaySignInStatus(String studentCode);

  /// Updates a single student attendance record (sign-in/sign-out entry).
  ///
  /// Returns a human-friendly success message from the API.
  Future<String> updateStudentAttendanceRecord({
    required String attendanceRecordCode,
    required String staffCode,
    DateTime? signedInAt,
    DateTime? signedOutAt,
    String? originalClassroomCode,
    String? currentClassroomCode,
    String? notes,
    String? timeZone,
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