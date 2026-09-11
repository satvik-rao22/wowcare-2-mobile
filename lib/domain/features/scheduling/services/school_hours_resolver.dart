import 'package:wowcare/domain/features/scheduling/entities/schedule_time.dart';
import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';

/// Resolved school-day windows from `childcareSchedule` for one weekday.
///
/// Times are [ScheduleTime], not Flutter's `TimeOfDay` — this is domain data,
/// and modelling it with a widget-library type is what kept this resolver
/// stranded in `presentation/features/scheduling/utils/`. Convert at the UI
/// boundary via `core/extensions/schedule_time_ext.dart`.
class SchoolDayHours {
  const SchoolDayHours({
    required this.label,
    required this.type,
    required this.startTime,
    required this.endTime,
    this.halfDay,
    this.durationMinutes,
    required this.openTime,
    required this.closeTime,
    required this.scheduleMonitorStart,
    required this.scheduleMonitorEnd,
    required this.ratioMonitorStart,
    required this.ratioMonitorEnd,
  });

  /// e.g. `Mon Schedule`
  final String label;

  /// e.g. `REGULAR`
  final String type;

  /// School open/close for calendar display (`hh:mm:ss a`).
  final String startTime;
  final String endTime;

  /// Half-day cutoff (`hh:mm:ss a`) when configured.
  final String? halfDay;

  /// Monitoring block size in minutes (`duration` from API).
  final int? durationMinutes;

  /// School operating hours (timeline axis).
  final ScheduleTime openTime;
  final ScheduleTime closeTime;

  /// Schedule-monitoring window used for forecast API requests.
  final ScheduleTime scheduleMonitorStart;
  final ScheduleTime scheduleMonitorEnd;

  /// Ratio-monitoring window (compliance checks).
  final ScheduleTime ratioMonitorStart;
  final ScheduleTime ratioMonitorEnd;
}

/// Maps `childcareSchedule` rows to calendar / forecast time bounds per weekday.
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

  /// Returns resolved bounds for [date], or null when the school is closed.
  SchoolDayHours? hoursFor(DateTime date) {
    final day = dayFor(date);
    if (day == null) return null;
    if (day.status != null && !day.isActive) return null;
    if (!day.isRegular) return null;

    final startTod = _parse24hTime(day.startTime);
    final endTod = _parse24hTime(day.endTime);
    if (startTod == null || endTod == null) return null;

    final scheduleStart = _parse24hTime(day.scheduleMonitorStartTime) ?? startTod;
    final scheduleEnd = _parse24hTime(day.scheduleMonitorEndTime) ?? endTod;
    final ratioStart = _parse24hTime(day.ratioMonitorStartTime) ?? scheduleStart;
    final ratioEnd = _parse24hTime(day.ratioMonitorEndTime) ?? scheduleEnd;

    final startLabel = _toShiftClockString(day.startTime);
    final endLabel = _toShiftClockString(day.endTime);
    if (startLabel.isEmpty || endLabel.isEmpty) return null;

    final halfDayRaw = day.halfDay?.trim();
    final halfDayLabel =
        halfDayRaw != null && halfDayRaw.isNotEmpty
            ? _toShiftClockString(halfDayRaw)
            : null;

    final blockDuration = (day.durationMinutes ?? 30).clamp(1, 24 * 60);

    return SchoolDayHours(
      label: day.label?.trim() ?? day.dayOfWeek,
      type: day.type?.trim() ?? 'REGULAR',
      startTime: startLabel,
      endTime: endLabel,
      halfDay: halfDayLabel?.isNotEmpty == true ? halfDayLabel : null,
      durationMinutes: blockDuration,
      openTime: startTod,
      closeTime: endTod,
      scheduleMonitorStart: scheduleStart,
      scheduleMonitorEnd: scheduleEnd,
      ratioMonitorStart: ratioStart,
      ratioMonitorEnd: ratioEnd,
    );
  }

  /// Total open minutes for [date] (school hours span).
  int? totalMinutesFor(DateTime date) {
    final hours = hoursFor(date);
    if (hours == null) return null;
    return _minutesBetween(hours.openTime, hours.closeTime);
  }

  static int _minutesBetween(ScheduleTime start, ScheduleTime end) {
    return (end.minutesOfDay - start.minutesOfDay).clamp(0, 24 * 60);
  }

  static ScheduleTime? _parse24hTime(String? raw) {
    final trimmed = raw?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    final parts = trimmed.split(':');
    if (parts.length < 2) return null;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return ScheduleTime(hour: h, minute: m);
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
