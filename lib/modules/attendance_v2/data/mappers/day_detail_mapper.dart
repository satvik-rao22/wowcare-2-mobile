import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/day_detail.dart';

/// Maps the existing `/staff-attendance/profile` detail response (per-session
/// `records.content[]` for a single day) into sessions + derived breaks.
class DayDetailMapper {
  const DayDetailMapper._();

  static DayDetail fromResponse(Map<String, dynamic>? body, DateTime date) {
    // The detail endpoint may return either the raw object or a {data:{...}}
    // envelope depending on the caller; handle both.
    final root = _map(body?['data']).isNotEmpty ? _map(body?['data']) : _map(body);
    final records = _map(root['records']);
    final content = (records['content'] as List?) ?? const [];

    final sessions = content
        .whereType<Map>()
        .map((e) => _mapSession(e.cast<String, dynamic>(), date))
        .whereType<AttendanceSession>()
        .toList()
      ..sort((a, b) => a.signInAt.compareTo(b.signInAt));

    return DayDetail(sessions: sessions, breaks: _breaks(sessions));
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static Map<String, dynamic> _map(dynamic v) =>
      v is Map ? v.cast<String, dynamic>() : <String, dynamic>{};

  static AttendanceSession? _mapSession(Map<String, dynamic> m, DateTime date) {
    final signInAt = _combine(date, m['signedInTime'] as String?);
    if (signInAt == null) return null;

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

    final signedOutBy = (m['signedOutBy'] as String?)?.trim();
    return AttendanceSession(
      recordCode: (m['code'] as String?) ?? '',
      classroomName: (m['classroomName'] as String?)?.trim() ?? '',
      signInAt: signInAt,
      signOutAt: signOutAt,
      signedInBy: (m['signedInBy'] as String?)?.trim() ?? '',
      signedOutBy: (signedOutBy == null || signedOutBy.isEmpty) ? null : signedOutBy,
      signOutSource: source,
      workedMinutes:
          ((m['attendedHours'] as int?) ?? 0) * 60 + ((m['attendedMinutes'] as int?) ?? 0),
    );
  }

  static List<AttendanceBreak> _breaks(List<AttendanceSession> sorted) {
    final out = <AttendanceBreak>[];
    for (var i = 0; i < sorted.length - 1; i++) {
      final outAt = sorted[i].signOutAt;
      if (outAt == null) continue;
      final nextIn = sorted[i + 1].signInAt;
      final minutes = nextIn.difference(outAt).inMinutes;
      if (minutes > 0) {
        out.add(AttendanceBreak(start: outAt, end: nextIn, minutes: minutes));
      }
    }
    return out;
  }

  static DateTime? _combine(DateTime date, String? hms) {
    if (hms == null || hms.trim().isEmpty) return null;
    final parts = hms.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return DateTime(date.year, date.month, date.day, h, m);
  }
}
