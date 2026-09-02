/// An unresolved past session that blocks the next sign-in: either still open
/// (`SIGNED_IN`, no sign-out) or auto-closed by the scheduler on a guessed
/// time. Drives the gate.
///
/// [staffCode] / [staffName] are only populated when an **admin** is looking at
/// someone else's open day — the bulk sign-in gate lists many staff at once.
/// For a staff resolving their own day they can be left empty.
class MissedSignout {
  const MissedSignout({
    required this.attendanceCode,
    required this.attendanceDate,
    required this.softSignOutAt,
    this.signInAt,
    this.classroomName,
    this.staffCode = '',
    this.staffName = '',
  });

  /// FK to `staff_attendance_record.code` (`STAR_…`).
  final String attendanceCode;
  final DateTime attendanceDate;

  /// Suggested sign-out — the scheduler's guess, else the school's end time.
  final DateTime softSignOutAt;

  final DateTime? signInAt;
  final String? classroomName;

  final String staffCode;
  final String staffName;

  /// "Sara Malik" -> "SM"; falls back to "?" when no name is carried.
  String get initials {
    final parts = staffName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
