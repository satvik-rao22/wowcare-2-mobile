import 'package:wowcare/domain/features/attendance/entities/staff_attendance_daily.dart';
import 'package:wowcare/domain/features/attendance/entities/student_attendance_daily.dart';

/// Combines a calendar [localDay] (date portion only) with wall-clock [t].
DateTime? dateAtAttendanceClock(
  DateTime localDay,
  StudentAttendanceTime? t,
) {
  if (t == null) return null;
  return DateTime(
    localDay.year,
    localDay.month,
    localDay.day,
    t.hour,
    t.minute,
    t.second,
  );
}

/// Same as [dateAtAttendanceClock] for staff attendance API time shapes.
DateTime? dateAtStaffAttendanceClock(
  DateTime localDay,
  StaffAttendanceTime? t,
) {
  if (t == null) return null;
  return DateTime(
    localDay.year,
    localDay.month,
    localDay.day,
    t.hour,
    t.minute,
    t.second,
  );
}

/// Parses [s] as a full instant (ISO-8601) or as a wall-clock time on [localDay].
DateTime? parseFlexibleAttendanceMoment(DateTime localDay, String s) {
  final t = s.trim();
  if (t.isEmpty) return null;

  final parsed = DateTime.tryParse(t);
  if (parsed != null) {
    return parsed.isUtc ? parsed.toLocal() : parsed;
  }

  final amPm = RegExp(
    r'^(\d{1,2}):(\d{2})(?::(\d{2}))?(?:\.\d+)?\s*([aApP][mM])\s*$',
  ).firstMatch(t);
  if (amPm != null) {
    var hour = int.parse(amPm.group(1)!);
    final minute = int.parse(amPm.group(2)!);
    final second = int.tryParse(amPm.group(3) ?? '0') ?? 0;
    final period = amPm.group(4)!.toUpperCase();
    if (period == 'PM' && hour != 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return DateTime(
      localDay.year,
      localDay.month,
      localDay.day,
      hour,
      minute,
      second,
    );
  }

  final hms = t.split('.').first.trim();
  final parts = hms.split(':');
  if (parts.length >= 2) {
    final hour = int.tryParse(parts[0]) ?? -1;
    final minute = int.tryParse(parts[1]) ?? -1;
    if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
      final second = parts.length >= 3 ? (int.tryParse(parts[2]) ?? 0) : 0;
      return DateTime(
        localDay.year,
        localDay.month,
        localDay.day,
        hour,
        minute,
        second,
      );
    }
  }

  return null;
}

String formatAttendedDurationLabel(Duration d) {
  if (d.isNegative || d.inSeconds <= 0) return '';

  final totalMinutes = d.inMinutes;
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;

  if (hours < 1) {
    if (minutes == 0 && d.inSeconds > 0) {
      return '${d.inSeconds} seconds';
    }
    return '$minutes minutes';
  }
  return '$hours hours $minutes minutes';
}

bool _onSameLocalCalendarDate(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

/// Computes attended-time label from two instants.
///
/// When both moments fall on the same local calendar date and [end] is not
/// after [start], [end] is advanced by one day (overnight session on same
/// displayed date).
String? attendedLabelFromMoments(DateTime? start, DateTime? end) {
  if (start == null || end == null) return null;

  var e = end;
  if (_onSameLocalCalendarDate(start, e) && !e.isAfter(start)) {
    e = e.add(const Duration(days: 1));
  }

  final delta = e.difference(start);
  if (delta.inSeconds <= 0) return null;

  return formatAttendedDurationLabel(delta);
}
