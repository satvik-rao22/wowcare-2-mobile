/// One row from `GET /api/v1/school/{schoolCode}/regular-schedule`
/// (`data.content[]`).
class SchoolRegularScheduleDay {
  const SchoolRegularScheduleDay({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.durationMinutes,
    this.halfDay,
    this.label,
    this.status,
  });

  /// e.g. `MONDAY`
  final String dayOfWeek;

  /// 24h time string, e.g. `09:00` or `09:00:00`
  final String startTime;

  /// 24h time string, e.g. `17:00` or `17:00:00`
  final String endTime;

  /// Monitoring block size in minutes (from regular-schedule API).
  final int? durationMinutes;

  /// Half-day cutoff time string when applicable, e.g. `13:00`.
  final String? halfDay;
  final String? label;

  /// `ACTIVE` or `INACTIVE` as returned by the API. Null means unknown.
  final String? status;

  bool get isActive => status?.toUpperCase() == 'ACTIVE';
}
