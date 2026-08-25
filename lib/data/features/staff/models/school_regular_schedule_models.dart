import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';

class SchoolRegularScheduleListModel {
  SchoolRegularScheduleListModel(this.days);

  final List<SchoolRegularScheduleDay> days;

  factory SchoolRegularScheduleListModel.fromResponse(
    Map<String, dynamic> json,
  ) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      return SchoolRegularScheduleListModel([]);
    }

    // Primary: school settings (`GET /api/v1/organization/schools/{code}`).
    final childcare = data['childcareSchedule'];
    if (childcare is List<dynamic>) {
      return SchoolRegularScheduleListModel(_parseDays(childcare));
    }

    // Legacy paginated regular-schedule list.
    final content = data['content'];
    if (content is List<dynamic>) {
      return SchoolRegularScheduleListModel(_parseDays(content));
    }

    return SchoolRegularScheduleListModel([]);
  }

  static List<SchoolRegularScheduleDay> _parseDays(List<dynamic> raw) {
    final days = <SchoolRegularScheduleDay>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final parsed = _parseDay(item);
      if (parsed != null) days.add(parsed);
    }
    return days;
  }

  static SchoolRegularScheduleDay? _parseDay(Map<String, dynamic> item) {
    final dayOfWeek = (item['dayOfWeek'] as String?)?.trim() ?? '';
    final startTime = (item['startTime'] as String?)?.trim() ?? '';
    final endTime = (item['endTime'] as String?)?.trim() ?? '';
    if (dayOfWeek.isEmpty || startTime.isEmpty || endTime.isEmpty) return null;

    final durationRaw =
        item['durationMinutes'] ?? item['duration'] ?? item['blockDuration'];
    int? durationMinutes;
    if (durationRaw is num) {
      durationMinutes = durationRaw.round();
    } else {
      durationMinutes = int.tryParse(durationRaw?.toString() ?? '');
    }

    return SchoolRegularScheduleDay(
      code: (item['code'] as String?)?.trim(),
      dayOfWeek: dayOfWeek.toUpperCase(),
      startTime: startTime,
      endTime: endTime,
      halfDay: (item['halfDay'] as String?)?.trim(),
      type: (item['type'] as String?)?.trim().toUpperCase(),
      label: (item['label'] as String?)?.trim(),
      scheduleMonitorStartTime: (item['scheduleMonitorStartTime'] as String?)
          ?.trim(),
      scheduleMonitorEndTime: (item['scheduleMonitorEndTime'] as String?)
          ?.trim(),
      ratioMonitorStartTime: (item['ratioMonitorStartTime'] as String?)?.trim(),
      ratioMonitorEndTime: (item['ratioMonitorEndTime'] as String?)?.trim(),
      durationMinutes: durationMinutes,
      status: (item['status'] as String?)?.trim().toUpperCase(),
    );
  }
}
