/// Implemented by student/staff daily attendance screens so a parent tab shell
/// can reload the list after attendance flows complete (e.g. form → pop).
abstract interface class DailyAttendanceParentRefresh {
  void refreshAfterReturningFromAttendanceFlow();
}
