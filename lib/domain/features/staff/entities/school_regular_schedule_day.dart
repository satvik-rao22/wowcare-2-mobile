/// One row from `GET /api/v1/organization/school/{schoolCode}/regular-schedule`
/// (`data.content[]`).
class SchoolRegularScheduleDay {
  const SchoolRegularScheduleDay({
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    this.durationMinutes,
    this.halfDay,
    this.label,
  });

  /// e.g. `MONDAY`
  final String dayOfWeek;
  final String startTime;
  final String endTime;

  /// Monitoring block size in minutes (from regular-schedule API).
  final int? durationMinutes;
  final String? halfDay;
  final String? label;
}
