import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../model/scheduling_models.dart';
import 'scheduling_legend.dart';
import 'staff_schedule_tile.dart';

/// Width of the right-side column used in every row of the schedule
/// table. The day label, status icon, and time pills all live in this
/// column so they stack vertically aligned.
const double kSchedulingStatusColumnWidth = 140;

/// Grid colour for the body row dividers — soft grey from the design spec.
const Color kSchedulingGridColor = Color(0xFFE9ECEF);

/// Blue border colour used to set the header row apart from the body.
const Color kSchedulingHeaderBorderColor = Color(0x332C62E2);

/// Pinkish background colour for the table's header row.
const Color kSchedulingHeaderBackground = Color(0xB2F9F5FA);

/// A single row of the schedule table: [left] cell + vertical divider +
/// fixed-width [right] cell, followed by a horizontal divider unless [isLast].
class SchedulingTableRow extends StatelessWidget {
  const SchedulingTableRow({
    super.key,
    required this.left,
    required this.right,
    this.onTap,
    this.isLast = false,
    this.dividerColor = kSchedulingGridColor,
    this.backgroundColor,
  });

  final Widget left;
  final Widget right;
  final VoidCallback? onTap;
  final bool isLast;
  final Color dividerColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          Container(width: 1, color: dividerColor),
          SizedBox(
            width: kSchedulingStatusColumnWidth,
            child: Center(child: right),
          ),
        ],
      ),
    );
    final tapped = onTap != null
        ? InkWell(onTap: onTap, child: row)
        : row;
    final filled = backgroundColor != null
        ? ColoredBox(color: backgroundColor!, child: tapped)
        : tapped;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        filled,
        if (!isLast) Container(height: 1, color: dividerColor),
      ],
    );
  }
}

class DayClassroomSection extends StatefulWidget {
  const DayClassroomSection({
    super.key,
    required this.classroom,
    this.initiallyExpanded = true,
    this.isLast = false,
  });

  final ClassroomDaySchedule classroom;
  final bool initiallyExpanded;
  final bool isLast;

  @override
  State<DayClassroomSection> createState() => _DayClassroomSectionState();
}

class _DayClassroomSectionState extends State<DayClassroomSection> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(covariant DayClassroomSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded = widget.initiallyExpanded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final staff = widget.classroom.staff;
    final hasStaff = staff.isNotEmpty;
    final headerIsLastInSection = !_expanded || !hasStaff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SchedulingTableRow(
          onTap: hasStaff
              ? () => setState(() => _expanded = !_expanded)
              : null,
          isLast: widget.isLast && headerIsLastInSection,
          left: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Text(
                  widget.classroom.classroomName,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                if (hasStaff)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.primaryColor,
                  ),
              ],
            ),
          ),
          right: _statusIcon(),
        ),
        if (_expanded)
          for (int i = 0; i < staff.length; i++)
            SchedulingTableRow(
              isLast: widget.isLast && i == staff.length - 1,
              left: StaffRowLeft(entry: staff[i]),
              right: StaffTimeRangePill(
                startTime: staff[i].startTime,
                endTime: staff[i].endTime,
              ),
            ),
      ],
    );
  }

  Widget _statusIcon() {
    switch (widget.classroom.ratioStatus) {
      case ClassroomRatioStatus.inRatio:
        return const RatioStatusIcon.inRatio();
      case ClassroomRatioStatus.underRatio:
        return const RatioStatusIcon.underRatio();
    }
  }
}
