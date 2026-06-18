import '../entities/staff_overtime_profile.dart';

/// Read interface for the Attendance V2 detail screen.
abstract class AttendanceV2Repository {
  /// Loads a staff member's attendance + overtime profile for a date range.
  Future<StaffOvertimeProfile> getStaffProfile({
    required String staffCode,
    String staffName,
    required DateTime from,
    required DateTime to,
  });
}
