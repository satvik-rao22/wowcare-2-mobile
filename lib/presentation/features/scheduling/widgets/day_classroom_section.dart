import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/common/widgets/highlightable_card.dart';
import '../model/scheduling_models.dart';
import '../utils/scheduling_block_status_style.dart';
import 'scheduling_day_timeline.dart';
import 'staff_schedule_tile.dart';

/// Width of the right-side column used in every row of the week schedule
/// table. The day label, status icon, and time pills all live in this column.
const double kSchedulingStatusColumnWidth = 140;

/// Grid colour for the body row dividers — soft grey from the design spec.
const Color kSchedulingGridColor = AppPalette.borderHairline;

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
    this.onStaffShiftTap,
    this.onStaffSlotTap,
    this.staffAttendanceStatusByCode,
    this.highlightShiftCode,
    this.highlightClassroomCode,
    this.onClassroomStatusTap,
  });

  /// Shift code from a notification deep-link; the matching shift row scrolls
  /// into view and flashes.
  final String? highlightShiftCode;

  /// Classroom code from a notification deep-link (SHIFT_UNDER_RATIO); in DAY
  /// view the matching classroom row scrolls into view and flashes.
  final String? highlightClassroomCode;

  /// Week view only — tap on the compliance (tick/red) icon. Switches to DAY
  /// view scrolled/highlighted to this classroom.
  final VoidCallback? onClassroomStatusTap;

  final ClassroomDaySchedule classroom;
  final SchedulingViewMode viewMode;
  final DateTime day;
  final bool initiallyExpanded;
  final bool isLast;

  /// Week view — tap on the time-range pill.
  final void Function(StaffScheduleEntry entry)? onStaffShiftTap;

  /// Day view — tap on a staff Gantt work/break block.
  final void Function(StaffScheduleEntry entry, StaffShiftSlotDetail detail)?
      onStaffSlotTap;

  /// Today's sign-in status keyed by staffCode, resolved at the screen level
  /// via the bulk `/staff-attendance/sign-in/status` POST. Used to color the
  /// avatar dot on each staff row (SIGNED_IN → green, ABSENT → red).
  final Map<String, String>? staffAttendanceStatusByCode;

  String? _attendanceStatusForStaff(String staffCode) {
    final map = staffAttendanceStatusByCode;
    if (map == null) return null;
    final key = staffCode.trim();
    if (key.isEmpty) return null;
    return map[key];
  }

  @override
  State<DayClassroomSection> createState() => _DayClassroomSectionState();
}

class _DayClassroomSectionState extends State<DayClassroomSection> {
  late final ValueNotifier<bool> _expanded =
      ValueNotifier<bool>(widget.initiallyExpanded);

  @override
  void didUpdateWidget(covariant DayClassroomSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initiallyExpanded != widget.initiallyExpanded) {
      _expanded.value = widget.initiallyExpanded;
    }
  }

  @override
  void dispose() {
    _expanded.dispose();
    super.dispose();
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

    return ValueListenableBuilder<bool>(
      valueListenable: _expanded,
      builder: (context, expanded, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Flash the classroom row when it's the under-ratio notification target.
          HighlightableCard(
            code: widget.classroom.classroomCode,
            highlightCode: widget.highlightClassroomCode,
            scrollOnHighlight: true,
            borderRadius: 8,
            child: SchedulingDayGanttRow(
              left: InkWell(
                onTap: hasStaff ? () => _expanded.value = !expanded : null,
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
                        expanded
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
          ),
          if (expanded)
            for (final entry in staff)
              SchedulingDayGanttRow(
                left: StaffRowLeft(
                  entry: entry,
                  attendanceStatus:
                      widget._attendanceStatusForStaff(entry.staffCode),
                ),
                right: SchedulingStaffDayTimeline(
                  slots: entry.staffDaySlots,
                  slotDetails: entry.staffSlotDetails,
                  day: widget.day,
                  classroomName: widget.classroom.classroomName,
                  dayStartMinutes: entry.timelineStartMinutes,
                  dayEndMinutes: entry.timelineEndMinutes,
                  slotMinutes: entry.slotMinutes,
                  staffName: entry.staffName,
                  onShiftSlotTap: widget.onStaffSlotTap == null
                      ? null
                      : (detail) => widget.onStaffSlotTap!(entry, detail),
                ),
              ),
        ],
      ),
    );
  }

  /// Week view — staff list with shift pills and compliance icon column.
  Widget _buildWeekView(BuildContext context) {
    final staff = widget.classroom.staff;
    final hasStaff = staff.isNotEmpty;

    return ValueListenableBuilder<bool>(
      valueListenable: _expanded,
      builder: (context, expanded, _) {
        final headerIsLastInSection = !expanded || !hasStaff;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SchedulingTableRow(
              onTap: hasStaff ? () => _expanded.value = !expanded : null,
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
                        expanded
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
            if (expanded)
              for (int i = 0; i < staff.length; i++)
                HighlightableCard(
                  code: staff[i].shiftCode,
                  highlightCode: widget.highlightShiftCode,
                  scrollOnHighlight: true,
                  borderRadius: 8,
                  child: SchedulingTableRow(
                    isLast: widget.isLast && i == staff.length - 1,
                    left: StaffRowLeft(
                      entry: staff[i],
                      attendanceStatus: widget._attendanceStatusForStaff(
                        staff[i].staffCode,
                      ),
                    ),
                    right: StaffTimeRangePill(
                      startTime: staff[i].startTime,
                      endTime: staff[i].endTime,
                      isPublished: staff[i].isPublished,
                      onTap: widget.onStaffShiftTap == null
                          ? null
                          : () => widget.onStaffShiftTap!(staff[i]),
                    ),
                  ),
                ),
          ],
        );
      },
    );
  }

  /// Week view only — ratio icon in the status column (not day Gantt left
  /// column). Tapping it opens DAY view scrolled/highlighted to this
  /// classroom, independent of the row's own expand/collapse tap.
  Widget _weekComplianceIcon() {
    final icon = SchedulingBlockStatusStyle.weekViewIconForClassroomStatus(
      widget.classroom.ratioStatus,
      size: 20,
    );
    if (widget.onClassroomStatusTap == null) return icon;
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: widget.onClassroomStatusTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: icon,
      ),
    );
  }
}
