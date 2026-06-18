import '../../core/config/av2_config.dart';
import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/staff_overtime_profile.dart';

/// Maps the raw `/staff-attendance/profile` response into module entities.
///
/// The API returns per-SESSION records; this groups them into per-day rollups
/// and derives regular/overtime from a daily threshold (client-side for now —
/// the backend does not yet send the split). Breaks are derived from the gaps
/// between sessions by the entity itself.
class StaffOvertimeMapper {
  const StaffOvertimeMapper._();

  static StaffOvertimeProfile fromResponse(
    Map<String, dynamic>? body, {
    required String fallbackStaffCode,
    required String fallbackStaffName,
    required DateTime rangeStart,
    required DateTime rangeEnd,
    int dailyRegularMinutes = Av2Config.defaultDailyRegularMinutes,
  }) {
    final data = _asMap(body?['data']);
    final agg = _asMap(data['aggregations']);
    final records = _asMap(data['records']);
    final content = (records['content'] as List?) ?? const [];

    final rows = content
        .whereType<Map>()
        .map((e) => e.cast<String, dynamic>())
        .toList();

    final first = rows.isNotEmpty ? rows.first : const <String, dynamic>{};

    // Group sessions by attendance date.
    final byDate = <String, List<AttendanceSession>>{};
    for (final m in rows) {
      final dateStr = (m['attendanceDate'] as String?) ?? '';
      if (dateStr.isEmpty) continue;
      final session = _mapSession(m, dateStr);
      if (session == null) continue;
      byDate.putIfAbsent(dateStr, () => []).add(session);
    }

    final days = <AttendanceDay>[];
    byDate.forEach((dateStr, sessions) {
      sessions.sort((a, b) => a.signInAt.compareTo(b.signInAt));
      final date = DateTime.tryParse(dateStr);
      if (date == null) return;
      final worked = sessions.fold<int>(0, (t, s) => t + s.workedMinutes);
      final regular = worked <= dailyRegularMinutes ? worked : dailyRegularMinutes;
      final overtime = worked <= dailyRegularMinutes ? 0 : worked - dailyRegularMinutes;
      days.add(
        AttendanceDay(
          date: date,
          isAbsent: false,
          regularMinutes: regular,
          overtimeMinutes: overtime,
          sessions: sessions,
          hasSystemClosedSession: sessions.any((s) => s.isSystemClosed),
        ),
      );
    });
    days.sort((a, b) => b.date.compareTo(a.date)); // newest first

    final totalRegular = days.fold<int>(0, (t, d) => t + d.regularMinutes);
    final totalOvertime = days.fold<int>(0, (t, d) => t + d.overtimeMinutes);
    final totalBreak = days.fold<int>(0, (t, d) => t + d.totalBreakMinutes);

    final aggregation = OvertimeAggregation(
      attendedDays: (agg['attendedDays'] as int?) ?? days.length,
      absentDays: (agg['absentDays'] as int?) ?? 0,
      totalRegularMinutes: totalRegular,
      totalOvertimeMinutes: totalOvertime,
      totalBreakMinutes: totalBreak,
    );

    final apiName = (first['staffName'] as String?)?.trim();
    return StaffOvertimeProfile(
      staffCode: (first['staffCode'] as String?) ?? fallbackStaffCode,
      staffName: (apiName != null && apiName.isNotEmpty) ? apiName : fallbackStaffName,
      designation: _humanizeDesignation(first['designation']),
      classroomName: (first['classroomName'] as String?)?.trim() ?? '',
      todayStatus: _deriveTodayStatus(byDate),
      dailyRegularMinutes: dailyRegularMinutes,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      aggregation: aggregation,
      days: days,
    );
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

  static AttendanceSession? _mapSession(Map<String, dynamic> m, String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return null;
    final signInAt = _combine(date, m['signedInTime'] as String?);
    if (signInAt == null) return null; // a session must have a sign-in

    final signOutAt = _combine(date, m['signedOutTime'] as String?);
    final outMethod = (m['signedOutMethod'] as String?)?.toUpperCase();
    final SignOutSource source;
    if (signOutAt == null) {
      source = SignOutSource.open;
    } else if (outMethod == 'SYSTEM') {
      source = SignOutSource.system;
    } else {
      source = SignOutSource.staff;
    }

    final hours = (m['attendedHours'] as int?) ?? 0;
    final minutes = (m['attendedMinutes'] as int?) ?? 0;
    final signedOutBy = (m['signedOutBy'] as String?)?.trim();

    return AttendanceSession(
      recordCode: (m['code'] as String?) ?? '',
      classroomName: (m['classroomName'] as String?)?.trim() ?? '',
      signInAt: signInAt,
      signOutAt: signOutAt,
      signedInBy: (m['signedInBy'] as String?)?.trim() ?? '',
      signedOutBy: (signedOutBy == null || signedOutBy.isEmpty) ? null : signedOutBy,
      signOutSource: source,
      workedMinutes: hours * 60 + minutes,
    );
  }

  /// "05:26:00" + a date → DateTime. Times are school-local; we attach the
  /// day's date. Returns null for null/empty.
  static DateTime? _combine(DateTime date, String? hms) {
    if (hms == null || hms.trim().isEmpty) return null;
    final parts = hms.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }

  /// ["LEAD_TEACHER"] → "Lead Teacher".
  static String _humanizeDesignation(dynamic d) {
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

  static TodayStatus _deriveTodayStatus(
    Map<String, List<AttendanceSession>> byDate,
  ) {
    final now = DateTime.now();
    final key =
        '${now.year}-${_two(now.month)}-${_two(now.day)}';
    final today = byDate[key];
    if (today == null || today.isEmpty) return TodayStatus.notMarked;
    if (today.any((s) => s.isOpen)) return TodayStatus.present;
    return TodayStatus.signedOut;
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
