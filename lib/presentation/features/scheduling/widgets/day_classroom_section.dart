import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../model/scheduling_models.dart';
import 'scheduling_legend.dart';
import 'staff_schedule_tile.dart';

/// Width of the right-side column used in every row of the schedule
/// table. The day label, status icon, and time pills all live in this
/// column so they stack vertically aligned.
const double kSchedulingStatusColumnWidth = 140;

/// Grid colour for the table dividers — matches the outer card border
/// (`Color(0x33162831)`) so the inside lines extend the outer frame.
const Color kSchedulingGridColor = Color(0x33162831);

/// A single row of the schedule table: [left] cell + vertical divider +
/// fixed-width [right] cell, followed by a horizontal divider unless [isLast].
class SchedulingTableRow extends StatelessWidget {
  const SchedulingTableRow({
    super.key,
    required this.left,
    required this.right,
    this.onTap,
    this.isLast = false,
  });

  final Widget left;
  final Widget right;
  final VoidCallback? onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final row = IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: left),
          Container(width: 1, color: kSchedulingGridColor),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tapped,
        if (!isLast) Container(height: 1, color: kSchedulingGridColor),
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
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
                const SizedBox(width: 4),
                if (hasStaff)
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 18,
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
