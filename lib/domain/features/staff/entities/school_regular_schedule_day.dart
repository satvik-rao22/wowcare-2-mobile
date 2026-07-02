/// One weekday row from school settings
/// (`GET /api/v1/organization/schools/{schoolCode}` → `data.childcareSchedule[]`).
class SchoolRegularScheduleDay {
  const SchoolRegularScheduleDay({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.code,
    this.label,
    this.halfDay,
    this.type,
    this.scheduleMonitorStartTime,
    this.scheduleMonitorEndTime,
    this.ratioMonitorStartTime,
    this.ratioMonitorEndTime,
    this.durationMinutes,
    this.status,
  });

  final String? code;

  /// e.g. `MONDAY`
  final String dayOfWeek;

  /// School open time (24h), e.g. `00:00:00`
  final String startTime;

  /// School close time (24h), e.g. `23:04:00`
  final String endTime;

  /// Half-day cutoff (24h), e.g. `12:00:00`
  final String? halfDay;

  /// e.g. `REGULAR`
  final String? type;

  /// e.g. `Mon Schedule`
  final String? label;

  /// Forecast / schedule-monitoring window start (24h).
  final String? scheduleMonitorStartTime;

  /// Forecast / schedule-monitoring window end (24h).
  final String? scheduleMonitorEndTime;

  /// Ratio-compliance monitoring window start (24h).
  final String? ratioMonitorStartTime;

  /// Ratio-compliance monitoring window end (24h).
  final String? ratioMonitorEndTime;

  /// Monitoring block size in minutes (`duration` from API).
  final int? durationMinutes;

  /// `ACTIVE` or `INACTIVE` as returned by the API. Null means unknown.
  final String? status;

  bool get isActive => status?.toUpperCase() == 'ACTIVE';

  bool get isRegular =>
      type == null || type!.trim().isEmpty || type!.toUpperCase() == 'REGULAR';
}
