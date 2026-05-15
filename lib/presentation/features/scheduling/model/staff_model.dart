import 'package:flutter/material.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';

class StaffModel {
  final String name;
  final DocumentImageWidget image;
  final int workedHours;
  final int totalHours;
  final String shift;
  final Color? statusColor;
  final String shiftDate;

  StaffModel({
    required this.name,
    required this.image,
    required this.workedHours,
    required this.totalHours,
    required this.shift,
    this.statusColor,
    this.shiftDate = '',
  });
}
