import '../../core/config/av2_config.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/staff_overtime_profile.dart';

/// Maps the `/staff-overtime-records/profile` response (per-day rollups,
/// server-computed) into the module's profile + day list. No client-side
/// overtime math — the server already split regular/overtime/break per day.
class OverviewMapper {
  const OverviewMapper._();

  static StaffOvertimeProfile fromResponse(
    Map<String, dynamic>? body, {
    required String fallbackStaffCode,
    required String fallbackStaffName,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final data = _map(body?['data']);
    final staff = _map(data['staff']);
    final period = _map(data['period']);
    final summary = _map(data['summary']);
    final daysJson = (data['days'] as List?) ?? const [];

    final days = daysJson
        .whereType<Map>()
        .map((e) => _mapDay(e.cast<String, dynamic>()))
        .whereType<AttendanceDay>()
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // newest first

    return StaffOvertimeProfile(
      staffCode: (staff['staffCode'] as String?) ?? fallbackStaffCode,
      staffName: ((staff['staffName'] as String?)?.trim().isNotEmpty ?? false)
          ? (staff['staffName'] as String).trim()
          : fallbackStaffName,
      designation: _humanize(staff['designation']),
      classroomName: (staff['classroomName'] as String?)?.trim() ?? '',
      todayStatus: _parseTodayStatus(staff['todayStatus'] as String?),
      dailyRegularMinutes: Av2Config.defaultDailyRegularMinutes,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      aggregation: _aggregation(summary, days),
      days: days,
      timeZone: (period['timeZone'] as String?)?.trim() ?? '',
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

  static int _int(dynamic v) => v is num ? v.toInt() : 0;
  static bool _bool(dynamic v) => v == true;

  static AttendanceDay? _mapDay(Map<String, dynamic> m) {
    final date = DateTime.tryParse((m['date'] as String?) ?? '');
    if (date == null) return null;
    final absence = _map(m['absence']);
    return AttendanceDay(
      date: date,
      status: _parseDayStatus(m['status'] as String?),
      regularMinutes: _int(m['regularMinutes']),
      overtimeMinutes: _int(m['overtimeMinutes']),
      breakMinutes: _int(m['breakMinutes']),
      totalMinutes: _int(m['totalMinutes']),
      hasOvertime: _bool(m['hasOvertime']),
      needsAttention: _bool(m['needsAttention']),
      // Absence details — read from a nested `absence` block or flat fields,
      // whichever the overview provides. `code` is what edit/delete target.
      absenceCode: (absence['code'] ?? absence['recordCode'] ?? m['absenceCode'])
          ?.toString(),
      absenceReason: (absence['reason'] ?? m['absenceReason'])?.toString(),
      absenceType: (absence['type'] ?? m['absenceType'])?.toString(),
      absenceFromDate: DateTime.tryParse(
          (absence['fromDate'] ?? absence['absenceFromDate'] ?? '').toString()),
      absenceToDate: DateTime.tryParse(
          (absence['toDate'] ?? absence['absenceToDate'] ?? '').toString()),
      absenceNote: (absence['note'] ?? m['absenceNote'])?.toString(),
      absenceMarkedByName:
          (absence['markedByName'] ?? m['markedByName'])?.toString(),
    );
  }

  /// Uses the server summary; falls back to summing days when the summary is
  /// empty but days carry data (guards backend stubs that return zero summary).
  static OvertimeAggregation _aggregation(
    Map<String, dynamic> summary,
    List<AttendanceDay> days,
  ) {
    var attended = _int(summary['attendedDays']);
    var absent = _int(summary['absentDays']);
    var regular = _int(summary['regularMinutes']);
    var overtime = _int(summary['overtimeMinutes']);
    var breaks = _int(summary['breakMinutes']);

    final summaryEmpty = regular == 0 && overtime == 0 && attended == 0;
    final daysHaveData = days.any((d) => d.totalMinutes > 0);
    if (summaryEmpty && daysHaveData) {
      regular = days.fold(0, (t, d) => t + d.regularMinutes);
      overtime = days.fold(0, (t, d) => t + d.overtimeMinutes);
      breaks = days.fold(0, (t, d) => t + d.breakMinutes);
      attended = days.where((d) => !d.isAbsent && d.totalMinutes > 0).length;
      absent = days.where((d) => d.isAbsent).length;
    }

    return OvertimeAggregation(
      attendedDays: attended,
      absentDays: absent,
      totalRegularMinutes: regular,
      totalOvertimeMinutes: overtime,
      totalBreakMinutes: breaks,
    );
  }

  static DayStatus _parseDayStatus(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'SIGNED_IN':
        return DayStatus.signedIn;
      case 'SIGNED_OUT':
        return DayStatus.signedOut;
      case 'ABSENT':
        return DayStatus.absent;
      default:
        return DayStatus.notMarked;
    }
  }

  static TodayStatus _parseTodayStatus(String? s) {
    switch ((s ?? '').toUpperCase()) {
      case 'PRESENT':
        return TodayStatus.present;
      case 'SIGNED_OUT':
        return TodayStatus.signedOut;
      case 'ABSENT':
        return TodayStatus.absent;
      default:
        return TodayStatus.notMarked;
    }
  }

  /// "ASSOCIATE_TEACHER" → "Associate Teacher". Accepts string or list.
  static String _humanize(dynamic d) {
    String raw = '';
    if (d is List && d.isNotEmpty) {
      raw = d.first.toString();
    } else if (d is String) {
      raw = d;
    }
    if (raw.trim().isEmpty) return 'Staff';
    return raw
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1).toLowerCase())
        .join(' ');
  }
}
