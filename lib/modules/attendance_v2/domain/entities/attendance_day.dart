/// Per-day status from the overview endpoint.
enum DayStatus { signedIn, signedOut, absent, notMarked }

/// A gap between two consecutive sessions in a day (lunch/break). Lives here so
/// both the day-detail mapper and the break-row widget can use it.
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

/// One day in the staff's range. All numbers are server-computed by the
/// overview endpoint (`/staff-overtime-records/profile`). Sessions are NOT here
/// — they load lazily into a [DayDetail] when the row is expanded.
class AttendanceDay {
  const AttendanceDay({
    required this.date,
    required this.status,
    this.regularMinutes = 0,
    this.overtimeMinutes = 0,
    this.breakMinutes = 0,
    this.totalMinutes = 0,
    this.hasOvertime = false,
    this.needsAttention = false,
  });

  final DateTime date;
  final DayStatus status;
  final int regularMinutes;
  final int overtimeMinutes;
  final int breakMinutes;
  final int totalMinutes;
  final bool hasOvertime;
  final bool needsAttention;

  bool get isAbsent => status == DayStatus.absent;
  bool get hasBreaks => breakMinutes > 0;
}
