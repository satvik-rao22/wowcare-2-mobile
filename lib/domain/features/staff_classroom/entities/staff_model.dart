import 'package:flutter/material.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';

class StaffModel {
  final String name;
  final DocumentImageWidget image;
  final double availableHours;
  final double scheduledHours;
  final String shift;
  final Color? statusColor;
  final String shiftDate;
  final String? shiftCode;

  final String? shiftStatus;

  StaffModel({
    required this.name,
    required this.image,
    required this.availableHours,
    required this.scheduledHours,
    required this.shift,
    this.statusColor,
    this.shiftDate = '',
    this.shiftCode,
    this.shiftStatus,
  });

  @Deprecated('Use availableHours instead.')
  int get workedHours => availableHours.round();

  @Deprecated('Use scheduledHours instead.')
  int get totalHours => scheduledHours.round();
}
