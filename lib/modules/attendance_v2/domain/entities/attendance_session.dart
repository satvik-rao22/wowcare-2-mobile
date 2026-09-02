/// How a session's sign-out was recorded. `system` marks an auto-close at
/// school end time (needs attention); `regularized` marks an admin/approved
/// correction.
enum SignOutSource { staff, admin, system, regularized, open }

/// One sign-in / sign-out pair within a day (a single attendance record row).
class AttendanceSession {
  const AttendanceSession({
    required this.recordCode,
    required this.classroomName,
    required this.signInAt,
    this.signOutAt,
    required this.signedInBy,
    this.signedOutBy,
    required this.signOutSource,
    required this.workedMinutes,
  });

  final String recordCode;
  final String classroomName;
  final DateTime signInAt;
  final DateTime? signOutAt;
  final String signedInBy;
  final String? signedOutBy;
  final SignOutSource signOutSource;
  final int workedMinutes;

  bool get isOpen => signOutAt == null;
  bool get isSystemClosed => signOutSource == SignOutSource.system;
}
