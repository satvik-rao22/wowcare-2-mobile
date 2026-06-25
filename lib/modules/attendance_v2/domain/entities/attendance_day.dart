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
    this.absenceCode,
    this.absenceReason,
    this.absenceType,
    this.absenceFromDate,
    this.absenceToDate,
    this.absenceNote,
    this.absenceMarkedByName,
  });

  final DateTime date;
  final DayStatus status;
  final int regularMinutes;
  final int overtimeMinutes;
  final int breakMinutes;
  final int totalMinutes;
  final bool hasOvertime;
  final bool needsAttention;

  // Absence record details (present on ABSENT days when the overview includes
  // them). [absenceCode] is required to edit/delete the absence.
  final String? absenceCode;
  final String? absenceReason;
  final String? absenceType; // FULL_DAY | HALF_DAY
  final DateTime? absenceFromDate;
  final DateTime? absenceToDate;
  final String? absenceNote;
  final String? absenceMarkedByName;

  bool get isAbsent => status == DayStatus.absent;
  bool get hasBreaks => breakMinutes > 0;
  bool get canEditAbsence => isAbsent && (absenceCode?.isNotEmpty ?? false);

  AttendanceDay copyWith({
    String? absenceCode,
    String? absenceReason,
    String? absenceType,
    DateTime? absenceFromDate,
    DateTime? absenceToDate,
    String? absenceNote,
    String? absenceMarkedByName,
  }) {
    return AttendanceDay(
      date: date,
      status: status,
      regularMinutes: regularMinutes,
      overtimeMinutes: overtimeMinutes,
      breakMinutes: breakMinutes,
      totalMinutes: totalMinutes,
      hasOvertime: hasOvertime,
      needsAttention: needsAttention,
      absenceCode: absenceCode ?? this.absenceCode,
      absenceReason: absenceReason ?? this.absenceReason,
      absenceType: absenceType ?? this.absenceType,
      absenceFromDate: absenceFromDate ?? this.absenceFromDate,
      absenceToDate: absenceToDate ?? this.absenceToDate,
      absenceNote: absenceNote ?? this.absenceNote,
      absenceMarkedByName: absenceMarkedByName ?? this.absenceMarkedByName,
    );
  }
}
