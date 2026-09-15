import 'package:wowcare/domain/features/attendance/entities/staff_attendance_profile_response.dart';

import '../../domain/entities/attendance_day.dart';
import '../../domain/entities/attendance_session.dart';
import '../../domain/entities/day_detail.dart';

/// Maps the existing `/staff-attendance/profile` detail response (per-session
/// `records.content[]` for a single day) into sessions + derived breaks.
class DayDetailMapper {
  const DayDetailMapper._();

  static DayDetail fromResponse(
    StaffAttendanceProfileResponse? body,
    DateTime date,
  ) {
    final sessions = (body?.records ?? const <StaffAttendanceProfileRecord>[])
        .map((r) => _mapSession(r, date))
        .whereType<AttendanceSession>()
        .toList()
      ..sort((a, b) => a.signInAt.compareTo(b.signInAt));

    return DayDetail(sessions: sessions, breaks: _breaks(sessions));
  }

  // ── helpers ────────────────────────────────────────────────────────────────

  static AttendanceSession? _mapSession(
    StaffAttendanceProfileRecord r,
    DateTime date,
  ) {
    final signInAt = _combine(date, r.signedInTime as String?);
    if (signInAt == null) return null;

    final signOutAt = _combine(date, r.signedOutTime as String?);
    final outMethod = r.signedOutMethod?.toUpperCase();
    final SignOutSource source;
    if (signOutAt == null) {
      source = SignOutSource.open;
    } else if (outMethod == 'SYSTEM') {
      source = SignOutSource.system;
    } else {
      source = SignOutSource.staff;
    }

    final signedOutBy = r.signedOutBy.trim();
    return AttendanceSession(
      recordCode: r.code ?? '',
      classroomName: r.classroomName?.trim() ?? '',
      signInAt: signInAt,
      signOutAt: signOutAt,
      signedInBy: r.signedInBy.trim(),
      signedOutBy: signedOutBy.isEmpty ? null : signedOutBy,
      signOutSource: source,
      workedMinutes: r.attendedHours * 60 + r.attendedMinutes,
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
