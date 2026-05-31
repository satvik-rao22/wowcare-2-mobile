/// Implemented by student/staff attendance tab screens (Daily, Custom, Absent)
/// so the tabbed shell can reload each tab's list/counts after an attendance
/// flow completes (e.g. form → pop, inline edit/delete).
abstract interface class AttendanceTabRefresh {
  void refreshAfterReturningFromAttendanceFlow();
}

/// Backwards-compatible alias for the original name.
typedef DailyAttendanceParentRefresh = AttendanceTabRefresh;
