import 'attendance_session.dart';

/// A gap between two consecutive sessions in the same day — the staff signed
/// out and signed back in later (e.g. a lunch break).
class AttendanceBreak {
  const AttendanceBreak({
    required this.start,
    required this.end,
    required this.minutes,
  });

  final DateTime start;
  final DateTime end;
  final int minutes;
}

/// A single calendar day in the staff's range. Either an attended day (with
/// regular/overtime rollup and its sessions) or an absence record.
class AttendanceDay {
  const AttendanceDay({
    required this.date,
    required this.isAbsent,
    this.regularMinutes = 0,
    this.overtimeMinutes = 0,
    this.sessions = const [],
    this.hasSystemClosedSession = false,
    this.absenceMarkedBy,
    this.absenceNote,
  });

  final DateTime date;
  final bool isAbsent;

  // Attended-day rollup (per-day, computed server-side).
  final int regularMinutes;
  final int overtimeMinutes;
  final List<AttendanceSession> sessions;
  final bool hasSystemClosedSession;

  // Absence-day fields.
  final String? absenceMarkedBy;
  final String? absenceNote;

  int get totalMinutes => regularMinutes + overtimeMinutes;
  bool get hasOvertime => overtimeMinutes > 0;
  bool get needsAttention =>
      hasSystemClosedSession || sessions.any((s) => s.isOpen);

  /// Minutes of break immediately after [index] (gap to the next session).
  /// 0 when there is no next session, the session is still open, or the
  /// sessions are back-to-back (a transfer).
  int breakAfterMinutes(int index) {
    if (index < 0 || index >= sessions.length - 1) return 0;
    final outAt = sessions[index].signOutAt;
    if (outAt == null) return 0;
    final gap = sessions[index + 1].signInAt.difference(outAt).inMinutes;
    return gap > 0 ? gap : 0;
  }

  /// All non-zero break intervals in the day, derived from the sessions.
  List<AttendanceBreak> get breaks {
    final out = <AttendanceBreak>[];
    for (var i = 0; i < sessions.length - 1; i++) {
      final minutes = breakAfterMinutes(i);
      if (minutes > 0) {
        out.add(
          AttendanceBreak(
            start: sessions[i].signOutAt!,
            end: sessions[i + 1].signInAt,
            minutes: minutes,
          ),
        );
      }
    }
    return out;
  }

  /// Total unpaid break time across the day (sum of the gaps).
  int get totalBreakMinutes =>
      breaks.fold(0, (sum, b) => sum + b.minutes);

  bool get hasBreaks => totalBreakMinutes > 0;
}
