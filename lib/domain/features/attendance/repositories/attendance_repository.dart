import '../entities/attendance_action_result.dart';
import '../entities/student_attendance_daily.dart';
import '../entities/student_attendance_custom.dart';
import '../entities/staff_attendance_daily.dart';
import '../entities/staff_attendance_absent.dart';
import '../entities/student_attendance_absent_form.dart';
import '../entities/student_attendance_expected_summary.dart';
import '../entities/qr_validation_result.dart';

abstract class AttendanceRepository {
  Future<StudentAttendanceDailyPage> getStudentAttendanceDaily({
    required String attendanceDate,
    String? fromAttendanceDate,
    String? toAttendanceDate,
    List<String>? classroomCodes,
    List<String>? studentCodes,
    List<String>? tagCodes,
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int page,
    int size,
  });

  /// Expected attendance summary for the daily "Expected Students" card.
  ///
  /// [classroomCode] is sent as `classroomCode` on the summary/card API.
  /// When null or empty, the repository may fall back to the first allowed
  /// classroom for the current user.
  Future<StudentAttendanceExpectedSummary> getStudentAttendanceExpectedSummary({
    String? classroomCode,
    bool schoolWide = false,
    bool forceRefresh = false,
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

  /// Student Absent records for activities feed (daily/custom tabs).
  ///
  /// Backend endpoint:
  /// `/api/v1/student-attendance/view/absent/records/activity`.
  /// Response shape matches [StudentAttendanceAbsentFormPage].
  Future<StudentAttendanceAbsentFormPage> getStudentAbsentRecordsActivity({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    List<String>? studentCodes,
    String? search,
    int page,
    int size,
  });

  /// Removes a student absence record (e.g. before override sign-in).
  ///
  /// Backend: `DELETE /api/v1/student-absence-records/{absenceRecordCode}`.
  Future<void> deleteStudentAbsenceRecord({
    required String absenceRecordCode,
    required String staffCode,
  });

  /// Removes a student attendance record (sign-in / sign-out / transfer day row).
  ///
  /// Backend: `DELETE /api/v1/student-attendance-records/{attendanceRecordCode}`.
  Future<void> deleteStudentAttendanceRecord({
    required String attendanceRecordCode,
    required String staffCode,
  });

  /// Removes a staff attendance record (sign-in / sign-out / transfer day row).
  ///
  /// Backend: `DELETE /api/v1/staff-attendance-records/{attendanceRecordCode}`.
  Future<void> deleteStaffAttendanceRecord({
    required String attendanceRecordCode,
    required String staffCode,
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
    required Map<String, bool> isExpectedTodayByStudentCode,
    String markAbsentMethod = 'APP',
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
    required Map<String, bool> isExpectedTodayByStaffCode,
    String markAbsentMethod = 'APP',
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
    String? signInAtFilter,
    String? signOutAtFilter,
    bool? isExpectedNotMarked,
    String? search,
    int page,
    int size,
  });

  /// Staff expected attendance summary for the daily "Expected Staff" card.
  ///
  /// [classroomCode] is sent as `classroomCode` on the summary/card API.
  Future<StudentAttendanceExpectedSummary> getStaffAttendanceExpectedSummary({
    String? classroomCode,
    bool schoolWide = false,
    bool forceRefresh = false,
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

  /// Current-day sign-in status for multiple staff members.
  ///
  /// Returns a map of `staffCode -> status` where status is typically
  /// `SIGNED_IN` or `ABSENT`.
  Future<Map<String, String>> getStaffTodaySignInStatusMap(
    List<String> staffCodes,
  );

  /// Current-day sign-in status for a single student.
  ///
  /// Returns a status string such as `SIGNED_IN` or `ABSENT`, or `null`
  /// if the backend did not return a status for this code.
  Future<String?> getStudentTodaySignInStatus(String studentCode);

  /// Current-day sign-in status for multiple students.
  ///
  /// Returns a map of `studentCode -> status` where status is typically
  /// `SIGNED_IN` or `ABSENT`.
  Future<Map<String, String>> getStudentTodaySignInStatusMap(
    List<String> studentCodes,
  );

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

  /// Creates student sign-in records.
  ///
  /// Mirrors backend payload for `/api/v1/student-attendance-records/sign-in`.
  Future<String> createStudentSignInRecords({
    required String attendanceDate,
    required String staffCode,
    required List<String> studentCodes,
    String? classroomCode,
    Map<String, String>? classroomCodeByStudentCode,
    String method = 'APP',
    bool isExpected = true,
    double latitude = 0,
    double longitude = 0,
    bool withinGeofence = false,
    String? timeZone,
    DateTime? occurredAt,
  });

  Future<QrValidationResult> validateQrCode({
    required String schoolCode,
    required String qrToken,
    required String useCase,
  });

  // --- Attendance mutations submitted from forms ---
  //
  // Each method takes the request payload the form assembled, applies the
  // allowed-classroom scope, performs the HTTP call via the data layer, and
  // returns the backend success/message. The presentation layer no longer
  // touches ApiClient directly.

  /// Submits a student sign-in (parent or staff variant).
  Future<AttendanceActionResult> submitStudentSignIn({
    required Map<String, dynamic> payload,
    required bool isParent,
  });

  /// Submits a student sign-out (parent or staff variant).
  Future<AttendanceActionResult> submitStudentSignOut({
    required Map<String, dynamic> payload,
    required bool isParent,
  });

  /// Submits a student classroom transfer.
  Future<AttendanceActionResult> submitStudentTransfer({
    required Map<String, dynamic> payload,
  });

  /// Submits a staff sign-in (admin bulk or teacher-self variant).
  Future<AttendanceActionResult> submitStaffSignIn({
    required Map<String, dynamic> payload,
    required bool isSelf,
  });

  /// Submits a staff sign-out.
  /// Set [isSelf] to true to use the self sign-out endpoint.
  Future<AttendanceActionResult> submitStaffSignOut({
    required Map<String, dynamic> payload,
    bool isSelf = false,
  });

  /// Submits a staff classroom transfer.
  Future<AttendanceActionResult> submitStaffTransfer({
    required Map<String, dynamic> payload,
  });

  /// Patches a staff daily attendance record by its row code.
  Future<Map<String, dynamic>?> updateStaffAttendanceDailyRecord({
    required String attendanceCode,
    required Map<String, dynamic> body,
  });

  // --- Attendance profile / absent reads (raw response maps) ---
  //
  // These return the raw backend JSON object so existing screen-level parsing
  // is preserved; the presentation layer no longer touches ApiClient. The
  // [queryParameters] are assembled by the caller (including date range,
  // paging and allowed-classroom scope).

  /// GET student attendance profile (present-day summary + records).
  Future<Map<String, dynamic>?> fetchStudentAttendanceProfile({
    required Map<String, dynamic> queryParameters,
  });

  /// GET student attendance profile absent-toggle list.
  Future<Map<String, dynamic>?> fetchStudentAttendanceProfileAbsentToggle({
    required Map<String, dynamic> queryParameters,
  });

  /// GET staff attendance profile (present-day summary + records).
  Future<Map<String, dynamic>?> fetchStaffAttendanceProfile({
    required Map<String, dynamic> queryParameters,
  });

  /// GET staff attendance profile absent-toggle list.
  Future<Map<String, dynamic>?> fetchStaffAttendanceProfileAbsentToggle({
    required Map<String, dynamic> queryParameters,
  });

  /// GET student absent view list (paginated, filterable).
  Future<Map<String, dynamic>?> fetchStudentAttendanceAbsentView({
    required Map<String, dynamic> queryParameters,
  });

  /// GET student absent view with classroom filter + allowed scope applied.
  Future<Map<String, dynamic>?> getStudentAttendanceAbsentView({
    required String fromAbsenceDate,
    required String toAbsenceDate,
    List<String>? classroomCodes,
    List<String>? tagCodes,
    String? search,
    int page = 0,
    int size = 10,
    List<String>? sort,
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
