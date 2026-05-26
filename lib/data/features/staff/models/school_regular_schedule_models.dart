import 'package:wowcare/domain/features/staff/entities/school_regular_schedule_day.dart';

class SchoolRegularScheduleListModel {
  SchoolRegularScheduleListModel(this.days);

  final List<SchoolRegularScheduleDay> days;

  factory SchoolRegularScheduleListModel.fromResponse(Map<String, dynamic> json) {
    final data = json['data'];
    if (data is! Map<String, dynamic>) {
      return SchoolRegularScheduleListModel([]);
    }
    final raw = data['content'];
    if (raw is! List<dynamic>) {
      return SchoolRegularScheduleListModel([]);
    }
    final days = <SchoolRegularScheduleDay>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) continue;
      final dayOfWeek = (item['dayOfWeek'] as String?)?.trim() ?? '';
      final startTime = (item['startTime'] as String?)?.trim() ?? '';
      final endTime = (item['endTime'] as String?)?.trim() ?? '';
      if (dayOfWeek.isEmpty || startTime.isEmpty || endTime.isEmpty) continue;
      final durationRaw =
          item['durationMinutes'] ?? item['duration'] ?? item['blockDuration'];
      int? durationMinutes;
      if (durationRaw is num) {
        durationMinutes = durationRaw.toInt();
      } else {
        durationMinutes = int.tryParse(durationRaw?.toString() ?? '');
      }
      days.add(
        SchoolRegularScheduleDay(
          dayOfWeek: dayOfWeek.toUpperCase(),
          startTime: startTime,
          endTime: endTime,
          durationMinutes: durationMinutes,
          halfDay: (item['halfDay'] as String?)?.trim(),
          label: (item['label'] as String?)?.trim(),
        ),
      );
    }
    return SchoolRegularScheduleListModel(days);
  }
}
