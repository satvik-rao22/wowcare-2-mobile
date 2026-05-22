import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../model/scheduling_models.dart';
import '../utils/scheduling_block_status_style.dart';
import 'scheduling_day_timeline.dart';
import 'staff_schedule_tile.dart';

/// Width of the right-side column used in every row of the week schedule
/// table. The day label, status icon, and time pills all live in this column.
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

/// Header for the daily classroom list (legend + collapse).
class DailyClassroomScheduleHeader extends StatelessWidget {
  const DailyClassroomScheduleHeader({
    super.key,
    required this.expandAll,
    required this.onToggleExpandAll,
  });

  final bool expandAll;
  final VoidCallback onToggleExpandAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: kSchedulingHeaderBackground,
        border: Border(
          bottom: BorderSide(color: kSchedulingHeaderBorderColor),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: kSchedulingDayLeftColumnWidth,
            child: InkWell(
              onTap: onToggleExpandAll,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
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
            ),
          ),
          Container(width: 1, color: kSchedulingHeaderBorderColor),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: SchedulingDayLegend(),
            ),
          ),
        ],
      ),
    );
  }
}

/// Week table row or daily Gantt block for one classroom (PRD Use Case 6).
class DayClassroomSection extends StatefulWidget {
  const DayClassroomSection({
    super.key,
    required this.classroom,
    required this.viewMode,
    required this.day,
    this.initiallyExpanded = true,
    this.isLast = false,
  });

  final ClassroomDaySchedule classroom;
  final SchedulingViewMode viewMode;
  final DateTime day;
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

  bool get _isDayView => widget.viewMode == SchedulingViewMode.day;

  @override
  Widget build(BuildContext context) {
    if (_isDayView) {
      return _buildDayView(context);
    }
    return _buildWeekView(context);
  }

  /// PRD Use Case 6 — expanded timeline, colour blocks, daily compliance icon.
  Widget _buildDayView(BuildContext context) {
    final staff = widget.classroom.staff;
    final hasStaff = staff.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SchedulingDayGanttRow(
          left: InkWell(
            onTap: hasStaff ? () => setState(() => _expanded = !_expanded) : null,
            child: Row(
              children: [
                Expanded(
                  child: Center(
                    child: ClassroomRowLeft(
                      classroomCode: widget.classroom.classroomCode,
                      classroomName: widget.classroom.classroomName,
                    ),
                  ),
                ),
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
          right: SchedulingClassroomDayTimeline(
            slots: widget.classroom.daySlots,
            slotDetails: widget.classroom.slotDetails,
            day: widget.day,
            classroomName: widget.classroom.classroomName,
            dayStartMinutes: widget.classroom.timelineStartMinutes,
            dayEndMinutes: widget.classroom.timelineEndMinutes,
            slotMinutes: widget.classroom.slotMinutes,
          ),
        ),
        if (_expanded)
          for (final entry in staff)
            SchedulingDayGanttRow(
              left: StaffRowLeft(entry: entry),
              right: SchedulingStaffDayTimeline(
                slots: entry.staffDaySlots,
                slotDetails: entry.staffSlotDetails,
                day: widget.day,
                classroomName: widget.classroom.classroomName,
                dayStartMinutes: entry.timelineStartMinutes,
                dayEndMinutes: entry.timelineEndMinutes,
                slotMinutes: entry.slotMinutes,
                staffName: entry.staffName,
              ),
            ),
      ],
    );
  }

  /// Week view — staff list with shift pills and compliance icon column.
  Widget _buildWeekView(BuildContext context) {
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
          left: Row(
            children: [
              Expanded(
                child: Center(
                  child: ClassroomRowLeft(
                    classroomCode: widget.classroom.classroomCode,
                    classroomName: widget.classroom.classroomName,
                  ),
                ),
              ),
              if (hasStaff)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 20,
                    color: AppColors.primaryColor,
                  ),
                ),
            ],
          ),
          right: _weekComplianceIcon(),
        ),
        if (_expanded)
          for (int i = 0; i < staff.length; i++)
            SchedulingTableRow(
              isLast: widget.isLast && i == staff.length - 1,
              left: StaffRowLeft(entry: staff[i]),
              right: StaffTimeRangePill(
                startTime: staff[i].startTime,
                endTime: staff[i].endTime,
                isPublished: staff[i].isPublished,
              ),
            ),
      ],
    );
  }

  /// Week view only — ratio icon in the status column (not day Gantt left column).
  Widget _weekComplianceIcon() {
    return SchedulingBlockStatusStyle.weekViewIconForClassroomStatus(
      widget.classroom.ratioStatus,
      size: 20,
    );
  }
}
