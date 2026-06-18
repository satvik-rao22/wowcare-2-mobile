import 'attendance_day.dart';

/// Today's live status for the header pill.
enum TodayStatus { present, signedOut, absent, notMarked }

/// Aggregated totals for the selected date range (header hero card).
class OvertimeAggregation {
  const OvertimeAggregation({
    required this.attendedDays,
    required this.absentDays,
    required this.totalRegularMinutes,
    required this.totalOvertimeMinutes,
    required this.totalBreakMinutes,
  });

  final int attendedDays;
  final int absentDays;
  final int totalRegularMinutes;
  final int totalOvertimeMinutes;
  final int totalBreakMinutes;

  int get totalAttendedMinutes => totalRegularMinutes + totalOvertimeMinutes;

  int get averageMinutesPerDay =>
      attendedDays == 0 ? 0 : (totalAttendedMinutes / attendedDays).round();

  /// Fraction of the bar that is regular (0..1). Guards divide-by-zero.
  double get regularFraction {
    final total = totalAttendedMinutes;
    if (total == 0) return 1;
    return totalRegularMinutes / total;
  }
}

/// The full payload behind the staff detail screen.
class StaffOvertimeProfile {
  const StaffOvertimeProfile({
    required this.staffCode,
    required this.staffName,
    required this.designation,
    required this.classroomName,
    required this.todayStatus,
    required this.dailyRegularMinutes,
    required this.rangeStart,
    required this.rangeEnd,
    required this.aggregation,
    required this.days,
  });

  final String staffCode;
  final String staffName;
  final String designation;
  final String classroomName;
  final TodayStatus todayStatus;
  final int dailyRegularMinutes;
  final DateTime rangeStart;
  final DateTime rangeEnd;
  final OvertimeAggregation aggregation;
  final List<AttendanceDay> days;

  /// Initials for the avatar, e.g. "Devi Vempati" -> "DV".
  String get initials {
    final parts = staffName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  int get needsAttentionCount => days.where((d) => d.needsAttention).length;
}
