import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import '../model/scheduling_models.dart';

/// Width of the LEFT (name) column of the day Gantt table.
const double _kLeftColumnWidth = 150;

/// Width of every dot in the timeline strip.
const double _kDotSize = 10;

/// Spacing between dots in the timeline strip.
const double _kDotGap = 2;

/// Day-view of the schedule. Renders an outer card with a header (legend +
/// "Collapse All"), a "Class Schedule" aggregate row per classroom, and a
/// Gantt-style row per staff entry.
class DayGanttTable extends StatefulWidget {
  const DayGanttTable({
    super.key,
    required this.classrooms,
  });

  final List<ClassroomDaySchedule> classrooms;

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
          label: 'Under Ratio/Break/Absent',
        ),
        _LegendDot(color: Color(0xFFACF3AA), label: 'In Ratio/Present'),
        _LegendDot(color: Color(0xFF5978F7), label: 'Over Ratio'),
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
  const _ClassroomBlock({required this.classroom, required this.expanded});

  final ClassroomDaySchedule classroom;
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
          right: _TimelineStrip(slots: widget.classroom.daySlots),
        ),
        if (_open)
          for (final s in staff)
            _GanttRow(
              left: _StaffLeft(entry: s),
              right: _TimelineStrip(slots: s.daySlots),
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

class _TimelineStrip extends StatelessWidget {
  const _TimelineStrip({required this.slots});

  final List<TimeSlotStatus> slots;

  @override
  Widget build(BuildContext context) {
    if (slots.isEmpty) {
      return SizedBox(
        height: _kDotSize,
        child: Text(
          'No schedule',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            color: AppColors.primaryColor.withValues(alpha: 0.5),
          ),
        ),
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < slots.length; i++) ...[
            _SlotDot(status: slots[i]),
            if (i != slots.length - 1) const SizedBox(width: _kDotGap),
          ],
        ],
      ),
    );
  }
}

class _SlotDot extends StatelessWidget {
  const _SlotDot({required this.status});

  final TimeSlotStatus status;

  static const Map<TimeSlotStatus, Color> _colors = {
    TimeSlotStatus.inRatio: Color(0xFFACF3AA),
    TimeSlotStatus.underRatio: Color(0xFFF38D8D),
    TimeSlotStatus.overRatio: Color(0xFF5978F7),
    TimeSlotStatus.empty: Color(0xFFE9ECEF),
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _kDotSize,
      height: _kDotSize,
      decoration: BoxDecoration(
        color: _colors[status],
        shape: BoxShape.circle,
      ),
    );
  }
}
