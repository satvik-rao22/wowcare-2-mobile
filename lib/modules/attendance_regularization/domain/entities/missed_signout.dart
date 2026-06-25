/// An unresolved soft sign-out (the staff forgot to sign out; the system
/// closed the session at the school end time). Drives the next-day gate.
class MissedSignout {
  const MissedSignout({
    required this.recordCode,
    required this.attendanceDate,
    required this.softSignOutAt,
    this.signInAt,
    this.classroomName,
  });

  final String recordCode;
  final DateTime attendanceDate;

  /// The school end time the system auto-applied.
  final DateTime softSignOutAt;

  final DateTime? signInAt;
  final String? classroomName;
}
