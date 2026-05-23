import '../../../core/util/color_utils.dart';
import '../../../domain/features/staff_scheduling/entities/schedule_entry.dart';

class ScheduleModel {
  final String name;
  final String avatarUrl;
  final String scheduledHours;
  final String actualHours;
  final List<String> slotColors;

  ScheduleModel({
    required this.name,
    required this.avatarUrl,
    required this.scheduledHours,
    required this.actualHours,
    required this.slotColors,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      name: json['name'],
      avatarUrl: json['avatar'],
      scheduledHours: json['scheduled'],
      actualHours: json['actual'],
      slotColors: List<String>.from(json['colors']),
    );
  }

  ScheduleEntryEntity toEntity() {
    return ScheduleEntryEntity(
      name: name,
      avatarUrl: avatarUrl,
      scheduledHours: scheduledHours,
      actualHours: actualHours,
      slotColors: slotColors.map((hex) => ColorUtils.fromHex(hex)).toList(),
    );
  }
}
