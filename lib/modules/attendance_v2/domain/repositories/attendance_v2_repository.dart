import '../entities/day_detail.dart';
import '../entities/staff_overtime_profile.dart';

/// Read interface for the Attendance V2 detail screen.
abstract class AttendanceV2Repository {
  /// Triggers the server-side overtime recompute for the range (must run
  /// before [getOverview] returns fresh data).
  Future<void> calculate({
    required String staffCode,
    required DateTime from,
    required DateTime to,
  });

  /// Loads the per-day overview (summary + day rollups, no sessions) for a
  /// staff member over a date range.
  Future<StaffOvertimeProfile> getOverview({
    required String staffCode,
    String staffName,
    required DateTime from,
    required DateTime to,
  });

  /// Loads the sessions + breaks for a single day (called when a row expands).
  Future<DayDetail> getDayDetail({
    required String staffCode,
    required DateTime date,
  });
}
