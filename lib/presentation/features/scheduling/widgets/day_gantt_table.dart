import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import '../model/scheduling_models.dart';

/// Width of the LEFT (name) column of the day Gantt table.
const double _kLeftColumnWidth = 150;

/// Visual size of each slot block.
const double _kSlotSize = 14;

/// Horizontal padding on each side of a slot — combined with the neighbour's
/// padding this becomes the visible gap (and doubles as the tap target).
const double _kSlotHPad = 3;

/// Vertical padding making each slot a more thumb-friendly hit target.
const double _kSlotVPad = 8;

/// Granularity of one slot in minutes.
const int _kSlotMinutes = 30;

/// First slot's start-of-day in minutes since midnight (07:00 AM).
const int _kDayStartMinutes = 7 * 60;

/// Day-view of the schedule. Renders an outer card with a header (legend +
/// "Collapse All"), a "Class Schedule" aggregate row per classroom, and a
/// Gantt-style row per staff entry. Tap any slot for slot details.
class DayGanttTable extends StatefulWidget {
  const DayGanttTable({
    super.key,
    required this.classrooms,
    required this.day,
  });

  final List<ClassroomDaySchedule> classrooms;
  final DateTime day;

  @override
  State<DayGanttTable> createState() => _DayGanttTableState();
}

class _DayGanttTableState extends State<DayGanttTable> {
  bool _expandAll = true;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0x33162831)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DayHeaderRow(
              expandAll: _expandAll,
              onToggleExpandAll: () =>
                  setState(() => _expandAll = !_expandAll),
            ),
            for (final c in widget.classrooms)
              _ClassroomBlock(
                classroom: c,
                day: widget.day,
                expanded: _expandAll,
              ),
          ],
        ),
      ),
    );
  }
}

class _DayHeaderRow extends StatelessWidget {
  const _DayHeaderRow({
    required this.expandAll,
    required this.onToggleExpandAll,
  });

  final bool expandAll;
  final VoidCallback onToggleExpandAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xB2F9F5FA),
        border: Border(
          bottom: BorderSide(color: Color(0x332C62E2)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: _kLeftColumnWidth,
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
          Container(width: 1, color: const Color(0x332C62E2)),
          const Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: _DayLegend(),
            ),
          ),
        ],
      ),
    );
  }
}

class _DayLegend extends StatelessWidget {
  const _DayLegend();

  @override
  Widget build(BuildContext context) {
    return const Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _LegendDot(
          color: Color(0xFFF38D8D),
          label: 'Not in Ratio/Break Time',
        ),
        _LegendDot(color: Color(0xFFACF3AA), label: 'In Ratio/Work Time'),
        _LegendDot(color: Color(0xFF5978F7), label: 'Extra staff'),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}

class _ClassroomBlock extends StatefulWidget {
  const _ClassroomBlock({
    required this.classroom,
    required this.day,
    required this.expanded,
  });

  final ClassroomDaySchedule classroom;
  final DateTime day;
  final bool expanded;

  @override
  State<_ClassroomBlock> createState() => _ClassroomBlockState();
}

class _ClassroomBlockState extends State<_ClassroomBlock> {
  late bool _open = widget.expanded;

  @override
  void didUpdateWidget(covariant _ClassroomBlock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded != widget.expanded) _open = widget.expanded;
  }

  @override
  Widget build(BuildContext context) {
    final staff = widget.classroom.staff;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GanttRow(
          left: InkWell(
            onTap: staff.isEmpty
                ? null
                : () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.classroom.classroomName,
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.primaryColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (staff.isNotEmpty)
                    Icon(
                      _open
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 18,
                      color: AppColors.primaryColor,
                    ),
                ],
              ),
            ),
          ),
          right: _TimelineWithAxis(
            slots: widget.classroom.daySlots,
            day: widget.day,
            classroomName: widget.classroom.classroomName,
          ),
        ),
        if (_open)
          for (final s in staff)
            _GanttRow(
              left: _StaffLeft(entry: s),
              right: _TimelineWithAxis(
                slots: s.daySlots,
                day: widget.day,
                classroomName: widget.classroom.classroomName,
              ),
            ),
      ],
    );
  }
}

class _GanttRow extends StatelessWidget {
  const _GanttRow({required this.left, required this.right});

  final Widget left;
  final Widget right;

  static const Color _divider = Color(0xFFE9ECEF);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: _divider)),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: _kLeftColumnWidth, child: left),
            Container(width: 1, color: _divider),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: right,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffLeft extends StatelessWidget {
  const _StaffLeft({required this.entry});

  final StaffScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          DocumentImageWidget(
            fileUuid: entry.staffName,
            name: entry.staffName,
            imageUrl: entry.photoUrl,
            size: 32,
            disableProfileLookupFallback: true,
            disableAttendanceStatusLookup: true,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  entry.staffName,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '${entry.scheduledHours}h │ ${entry.availableHours}h',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Horizontally scrollable strip of slot blocks. Time is intentionally NOT
/// shown beneath the strip — it's revealed in the slot's tap-triggered popover.
class _TimelineWithAxis extends StatelessWidget {
  const _TimelineWithAxis({
    required this.slots,
    required this.day,
    required this.classroomName,
  });

  final List<TimeSlotStatus> slots;
  final DateTime day;
  final String classroomName;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return SizedBox(
        height: _kSlotSize + _kSlotVPad * 2,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'No schedule',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              color: AppColors.primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < slots.length; i++)
            _SlotTapTarget(
              status: slots[i],
              onTap: () => _showSlotDetails(
                context,
                slotIndex: i,
                status: slots[i],
              ),
            ),
        ],
      ),
    );
  }

  void _showSlotDetails(
    BuildContext context, {
    required int slotIndex,
    required TimeSlotStatus status,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) => _SlotDetailsDialog(
        day: day,
        slotIndex: slotIndex,
        classroomName: classroomName,
        status: status,
      ),
    );
  }
}

/// One slot — visible rounded square + transparent padding that doubles as
/// a generous thumb-tap target.
class _SlotTapTarget extends StatelessWidget {
  const _SlotTapTarget({required this.status, required this.onTap});

  final TimeSlotStatus status;
  final VoidCallback onTap;

  static const Map<TimeSlotStatus, Color> _colors = {
    TimeSlotStatus.inRatio: Color(0xFFACF3AA),
    TimeSlotStatus.underRatio: Color(0xFFF38D8D),
    TimeSlotStatus.overRatio: Color(0xFF5978F7),
    TimeSlotStatus.empty: Color(0xFFE9ECEF),
  };

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _kSlotHPad,
          vertical: _kSlotVPad,
        ),
        child: Container(
          width: _kSlotSize,
          height: _kSlotSize,
          decoration: BoxDecoration(
            color: _colors[status],
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }
}

/// Popover-style details for one slot, shown via [showDialog] on tap.
class _SlotDetailsDialog extends StatelessWidget {
  const _SlotDetailsDialog({
    required this.day,
    required this.slotIndex,
    required this.classroomName,
    required this.status,
  });

  final DateTime day;
  final int slotIndex;
  final String classroomName;
  final TimeSlotStatus status;

  @override
  Widget build(BuildContext context) {
    final startMin = _kDayStartMinutes + slotIndex * _kSlotMinutes;
    final start = TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60);
    final endMin = startMin + _kSlotMinutes;
    final end = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);

    final counts = _countsFor(status);
    final badge = _badgeLabel(status);
    final description = _descriptionFor(status);

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 320),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, MMM d, yyyy').format(day),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatTime(start)} - ${_formatTime(end)}',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        classroomName,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Divider(
                height: 1,
                color: AppColors.primaryColor.withValues(alpha: 0.12),
              ),
              const SizedBox(height: 12),
              _CountRow(
                color: AppColors.lightBlueProgressBar,
                label: 'Expected Students',
                count: counts.expected,
              ),
              const SizedBox(height: 6),
              _CountRow(
                color: AppColors.mustardProgressBar,
                label: 'Required Staff',
                count: counts.required,
              ),
              const SizedBox(height: 6),
              _CountRow(
                color: AppColors.colorBox3,
                label: 'Scheduled Staff',
                count: counts.scheduled,
              ),
              const SizedBox(height: 12),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: AppColors.primaryColor.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final int h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final String mm = t.minute.toString().padLeft(2, '0');
    final String ap = t.hour < 12 ? 'AM' : 'PM';
    return '$h12:$mm $ap';
  }

  String _badgeLabel(TimeSlotStatus s) {
    switch (s) {
      case TimeSlotStatus.overRatio:
        return 'Extra Staff';
      case TimeSlotStatus.inRatio:
        return 'In Ratio';
      case TimeSlotStatus.underRatio:
        return 'Break / Absent';
      case TimeSlotStatus.empty:
        return 'No Schedule';
    }
  }

  String _descriptionFor(TimeSlotStatus s) {
    switch (s) {
      case TimeSlotStatus.overRatio:
      case TimeSlotStatus.inRatio:
        return 'This block is inside the monitoring window and counts toward daily compliance.';
      case TimeSlotStatus.underRatio:
        return 'This block flags a ratio gap or break time and does not count toward staff compliance.';
      case TimeSlotStatus.empty:
        return 'No schedule recorded for this slot.';
    }
  }

  _SlotCounts _countsFor(TimeSlotStatus s) {
    switch (s) {
      case TimeSlotStatus.overRatio:
        return const _SlotCounts(expected: 0, required: 0, scheduled: 3);
      case TimeSlotStatus.inRatio:
        return const _SlotCounts(expected: 8, required: 2, scheduled: 2);
      case TimeSlotStatus.underRatio:
        return const _SlotCounts(expected: 8, required: 2, scheduled: 1);
      case TimeSlotStatus.empty:
        return const _SlotCounts(expected: 0, required: 0, scheduled: 0);
    }
  }
}

class _SlotCounts {
  const _SlotCounts({
    required this.expected,
    required this.required,
    required this.scheduled,
  });

  final int expected;
  final int required;
  final int scheduled;
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.color,
    required this.label,
    required this.count,
  });

  final Color color;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.fieldBackgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}
