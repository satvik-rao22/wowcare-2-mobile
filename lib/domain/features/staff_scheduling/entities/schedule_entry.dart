import 'package:flutter/material.dart';

class ScheduleEntryEntity {
  final String name;
  final String avatarUrl;
  final String scheduledHours;
  final String actualHours;
  final List<Color> slotColors;

  ScheduleEntryEntity({
    required this.name,
    required this.avatarUrl,
    required this.scheduledHours,
    required this.actualHours,
    required this.slotColors,
  });
}
