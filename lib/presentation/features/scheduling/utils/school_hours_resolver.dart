import 'package:flutter/material.dart';

import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';

/// Resolved open/close window for the schedule calendar (`hh:mm:ss a`).
class SchoolDayHours {
  const SchoolDayHours({
    required this.startTime,
    required this.endTime,
    this.durationMinutes,
    this.startTimeOfDay,
    this.endTimeOfDay,
  });

  final String startTime;
  final String endTime;

  /// Monitoring block size in minutes for forecast APIs.
  final int? durationMinutes;

  /// 24h bounds used when building forecast requests.
  final TimeOfDay? startTimeOfDay;
  final TimeOfDay? endTimeOfDay;
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
    final startTod = _parse24hTime(day.startTime);
    final endTod = _parse24hTime(day.endTime);
    final start = _toShiftClockString(day.startTime);
    final end = _toShiftClockString(day.endTime);
    if (start.isEmpty || end.isEmpty || startTod == null || endTod == null) {
      return null;
    }
    final blockDuration = (day.durationMinutes ?? 30).clamp(1, 24 * 60);
    return SchoolDayHours(
      startTime: start,
      endTime: end,
      durationMinutes: blockDuration,
      startTimeOfDay: startTod,
      endTimeOfDay: endTod,
    );
  }

  /// Total open minutes for [date] (school hours span).
  int? totalMinutesFor(DateTime date) {
    final hours = hoursFor(date);
    if (hours?.startTimeOfDay == null || hours?.endTimeOfDay == null) {
      return null;
    }
    return _minutesBetween(hours!.startTimeOfDay!, hours.endTimeOfDay!);
  }

  static int _minutesBetween(TimeOfDay start, TimeOfDay end) {
    final startMin = start.hour * 60 + start.minute;
    final endMin = end.hour * 60 + end.minute;
    return (endMin - startMin).clamp(0, 24 * 60);
  }

  static TimeOfDay? _parse24hTime(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
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
