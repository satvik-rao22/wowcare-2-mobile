import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';

/// Resolved open/close window for the schedule calendar (`hh:mm:ss a`).
class SchoolDayHours {
  const SchoolDayHours({
    required this.startTime,
    required this.endTime,
  });

  final String startTime;
  final String endTime;
}

/// Maps school regular-schedule API rows to calendar time bounds per weekday.
class SchoolHoursResolver {
  const SchoolHoursResolver(this._byDay);

  final Map<String, SchoolRegularScheduleDay> _byDay;

  factory SchoolHoursResolver.fromDays(List<SchoolRegularScheduleDay> days) {
    final map = <String, SchoolRegularScheduleDay>{};
    for (final d in days) {
      final key = d.dayOfWeek.trim().toUpperCase();
      if (key.isNotEmpty) map[key] = d;
    }
    return SchoolHoursResolver(map);
  }

  static String dayOfWeekKey(DateTime date) {
    const keys = [
      'MONDAY',
      'TUESDAY',
      'WEDNESDAY',
      'THURSDAY',
      'FRIDAY',
      'SATURDAY',
      'SUNDAY',
    ];
    return keys[date.weekday - 1];
  }

  SchoolRegularScheduleDay? dayFor(DateTime date) =>
      _byDay[dayOfWeekKey(date)];

  /// Returns calendar bounds for [date], or null if the school has no hours that day.
  SchoolDayHours? hoursFor(DateTime date) {
    final day = dayFor(date);
    if (day == null) return null;
    final start = _toShiftClockString(day.startTime);
    final end = _toShiftClockString(day.endTime);
    if (start.isEmpty || end.isEmpty) return null;
    return SchoolDayHours(startTime: start, endTime: end);
  }

  /// API times are typically `HH:mm` or `HH:mm:ss` (24h).
  static String _toShiftClockString(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';

    final parts = trimmed.split(':');
    if (parts.length < 2) return '';

    final h24 = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final secondPart = parts.length > 2 ? parts[2].split('.').first : '0';
    final second = int.tryParse(secondPart) ?? 0;

    final period = h24 >= 12 ? 'PM' : 'AM';
    var h12 = h24 % 12;
    if (h12 == 0) h12 = 12;

    return '${h12.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}:'
        '${second.toString().padLeft(2, '0')} $period';
  }
}
