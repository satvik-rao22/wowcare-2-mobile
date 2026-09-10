import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

import '../model/scheduling_models.dart';

/// Colours and labels for staff shift timelines (work/break).
/// Intentionally separate from [SchedulingBlockStatusStyle] (forecast ratio).
class SchedulingStaffShiftStyle {
  const SchedulingStaffShiftStyle._();

  static const Color workTimeColor = Color(0xFFACF3AA);
  static const Color breakTimeColor = Color(0xFFF38D8D);
  static const Color outsideShiftColor = AppPalette.borderHairline;

  static Color slotColor(StaffShiftSlotStatus status) {
    switch (status) {
      case StaffShiftSlotStatus.workTime:
        return workTimeColor;
      case StaffShiftSlotStatus.breakTime:
        return breakTimeColor;
      case StaffShiftSlotStatus.empty:
        return outsideShiftColor;
    }
  }

  static String slotLabel(StaffShiftSlotStatus status) {
    switch (status) {
      case StaffShiftSlotStatus.workTime:
        return 'Working Time';
      case StaffShiftSlotStatus.breakTime:
        return 'Break Time';
      case StaffShiftSlotStatus.empty:
        return 'Outside shift';
    }
  }

  static Widget dayLegendDot(StaffShiftSlotStatus status) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        color: slotColor(status),
        shape: BoxShape.circle,
      ),
    );
  }
}
