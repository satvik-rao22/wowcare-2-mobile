import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import 'day_classroom_section.dart';

/// Header row of the schedule table — "Collapse/Expand All" on the left,
/// the selected day label on the right. Uses [SchedulingTableRow] so the
/// vertical divider lines up with every classroom row below.
class WeekClassroomHeaderRow extends StatelessWidget {
  const WeekClassroomHeaderRow({
    super.key,
    required this.dayLabel,
    required this.expandAll,
    required this.onToggleExpandAll,
  });

  final String dayLabel;
  final bool expandAll;
  final VoidCallback onToggleExpandAll;

  @override
  Widget build(BuildContext context) {
    return SchedulingTableRow(
      onTap: onToggleExpandAll,
      left: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Text(
          expandAll ? 'Collapse All' : 'Expand All',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryColor,
          ),
        ),
      ),
      right: Text(
        dayLabel,
        style: const TextStyle(
          fontFamily: 'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}
