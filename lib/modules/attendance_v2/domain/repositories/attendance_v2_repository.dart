import '../entities/av2_classroom.dart';
import '../entities/av2_staff_summary.dart';
import '../entities/day_detail.dart';
import '../entities/staff_overtime_profile.dart';

/// Read interface for the Attendance V2 detail screen.
abstract class AttendanceV2Repository {
  /// Active staff for the current school (admin "switch staff" picker).
  Future<List<Av2StaffSummary>> getStaff();

  /// Active classrooms/locations for the current school (for the add-attendance
  /// room pickers).
  Future<List<Av2Classroom>> getClassrooms();

  /// Adds an attendance session: a sign-in and/or a sign-out (each in its own
  /// classroom). Times are wall-clock in the school [timeZone].
  Future<void> addAttendance({
    required String staffCode,
    required DateTime date,
    required String timeZone,
    String? signInClassroomCode,
    DateTime? signInLocal,
    String? signOutClassroomCode,
    DateTime? signOutLocal,
  });

  /// Triggers the server-side overtime recompute for the range (must run
  /// before [getOverview] returns fresh data).
  Future<void> calculate({
    required String staffCode,
    required DateTime from,
    required DateTime to,
  });

  /// Loads one page of the per-day overview (summary + day rollups, no
  /// sessions). The endpoint is paginated; pass [page]/[size] and the
  /// [overtimeOnly]/[absentOnly] server filters.
  Future<StaffOvertimeProfile> getOverview({
    required String staffCode,
    String staffName,
    required DateTime from,
    required DateTime to,
    int page,
    int size,
    bool overtimeOnly,
    bool absentOnly,
  });

  /// Loads the sessions + breaks for a single day (called when a row expands).
  Future<DayDetail> getDayDetail({
    required String staffCode,
    required DateTime date,
  });

  /// Edits an attendance session's sign-in/out. [signInLocal]/[signOutLocal]
  /// are wall-clock times in the school's [timeZone]; the impl converts to UTC.
  Future<void> editSession({
    required String recordCode,
    required String staffCode,
    required DateTime signInLocal,
    DateTime? signOutLocal,
    required String timeZone,
  });

  /// Deletes an attendance session record (admin only).
  Future<void> deleteSession({
    required String recordCode,
    required String staffCode,
  });

  /// Edits an absence record (admin only); also syncs the shift calendar.
  Future<void> editAbsence({
    required String code,
    required String staffCode,
    required DateTime fromDate,
    required DateTime toDate,
    required String reason,
    required String type,
    required String note,
  });

  /// Deletes an absence record (admin only).
  Future<void> deleteAbsence({
    required String code,
    required String staffCode,
  });
}
