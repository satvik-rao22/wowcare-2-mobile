import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import '../model/scheduling_models.dart';
import '../utils/scheduling_block_status_style.dart';
import '../utils/scheduling_staff_shift_style.dart';

/// Left column width for daily classroom Gantt rows.
const double kSchedulingDayLeftColumnWidth = 152;

/// Extra scroll width after the last slot so the closing time label is not clipped.
const double kDayTimelineEndLabelReservePx = 52;

/// Minimum gap between adjacent hour labels on the axis.
const double _kHourLabelMinGap = 8;

/// Day Gantt block size (larger for mobile legibility).
const double kDayTimelineBlockSize = 22;
const double kDayTimelineSlotHPad = 4;
const double kDayTimelineSlotVPad = 6;

double dayTimelineSlotStrideWidth() =>
    kDayTimelineBlockSize + kDayTimelineSlotHPad * 2;

/// Fixed height for blocks row + hour labels (used instead of IntrinsicHeight).
double get kDayTimelineTrackHeight =>
    kDayTimelineBlockSize + kDayTimelineSlotVPad * 2 + 4 + 14;

const int _kDefaultSlotMinutes = 30;
const int _kDefaultDayStartMinutes = 7 * 60;

/// Legend for daily view: classroom ratio colours only (work/break shown above).
class SchedulingDayLegend extends StatelessWidget {
  const SchedulingDayLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _RatioLegendDot(kind: SchedulingBlockStatusKind.underRatio),
        _RatioLegendDot(kind: SchedulingBlockStatusKind.inRatio),
        _RatioLegendDot(kind: SchedulingBlockStatusKind.extraStaff),
      ],
    );
  }
}

class _RatioLegendDot extends StatelessWidget {
  const _RatioLegendDot({required this.kind});

  final SchedulingBlockStatusKind kind;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SchedulingBlockStatusStyle.dayLegendDot(kind),
        const SizedBox(width: 6),
        Text(
          SchedulingBlockStatusStyle.ratioBadgeLabel(kind),
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

String _formatHourAxisLabel(int minutesSinceMidnight) {
  final hour = minutesSinceMidnight ~/ 60;
  final minute = minutesSinceMidnight % 60;
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  final period = hour < 12 ? 'AM' : 'PM';
  if (minute == 0) return '$h12:00 $period';
  return '$h12:${minute.toString().padLeft(2, '0')} $period';
}

/// Horizontal blocks row + school-hours axis (start through end) under grid.
class SchedulingDayTimelineTrack extends StatelessWidget {
  const SchedulingDayTimelineTrack({
    super.key,
    required this.slotCount,
    required this.dayStartMinutes,
    required this.dayEndMinutes,
    required this.slotMinutes,
    required this.blocks,
    this.emptyMessage,
  });

  final int slotCount;
  final int dayStartMinutes;
  final int dayEndMinutes;
  final int slotMinutes;
  final List<Widget> blocks;
  final String? emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (slotCount <= 0 || blocks.isEmpty) {
      return SizedBox(
        height: kDayTimelineTrackHeight,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            emptyMessage ?? 'No schedule',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              color: AppColors.primaryColor.withValues(alpha: 0.5),
            ),
          ),
        ),
      );
    }

    final slot = slotMinutes > 0 ? slotMinutes : _kDefaultSlotMinutes;
    final anchor =
        dayStartMinutes > 0 ? dayStartMinutes : _kDefaultDayStartMinutes;
    final axisEnd = dayEndMinutes > anchor
        ? dayEndMinutes
        : anchor + slotCount * slot;
    final stride = dayTimelineSlotStrideWidth();
    // Slot grid uses ceil(minutes/slot); track width must match that grid, not
    // the exact minute span, or the blocks row overflows by up to 1 stride unit.
    final layoutSlotCount = slotCount > blocks.length ? slotCount : blocks.length;
    final gridMinutes = layoutSlotCount * slot;
    final gridWidthPx = layoutSlotCount * stride;
    final endLabelReserve = kDayTimelineEndLabelReservePx;
    final trackWidthPx = gridWidthPx + endLabelReserve;
    final rowBlocks = List<Widget>.from(blocks);
    for (var i = blocks.length; i < layoutSlotCount; i++) {
      rowBlocks.add(const _EmptyTimelineSlot());
    }

    return SizedBox(
      height: kDayTimelineTrackHeight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const ClampingScrollPhysics(),
        clipBehavior: Clip.hardEdge,
        child: SizedBox(
          width: trackWidthPx,
          height: kDayTimelineTrackHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...rowBlocks,
                  SizedBox(width: endLabelReserve),
                ],
              ),
              const SizedBox(height: 4),
              _DayTimelineHourAxis(
                anchorMinutes: anchor,
                axisEndMinutes: axisEnd,
                gridMinutes: gridMinutes,
                gridWidthPx: gridWidthPx,
                endLabelReservePx: endLabelReserve,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hour labels at every school tick; positions are nudged so labels never overlap.
class _DayTimelineHourAxis extends StatelessWidget {
  const _DayTimelineHourAxis({
    required this.anchorMinutes,
    required this.axisEndMinutes,
    required this.gridMinutes,
    required this.gridWidthPx,
    required this.endLabelReservePx,
  });

  final int anchorMinutes;
  final int axisEndMinutes;
  final int gridMinutes;
  final double gridWidthPx;
  final double endLabelReservePx;

  static final TextStyle _labelStyle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 10,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor.withValues(alpha: 0.55),
    height: 1.2,
  );

  static double _measureLabelWidth(BuildContext context, String text) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: _labelStyle),
      textDirection: Directionality.of(context),
      maxLines: 1,
    )..layout();
    return painter.width;
  }

  /// Places each tick label at its proportional offset, pushing right when needed
  /// so full strings (e.g. "12:01 AM" next to "1:00 AM") stay readable.
  static List<({int tickMinutes, double left})> _layoutHourLabels({
    required BuildContext context,
    required List<int> ticks,
    required int anchorMinutes,
    required int spanMinutes,
    required double gridWidthPx,
    required double trackWidthPx,
  }) {
    if (ticks.isEmpty) return const [];

    final span = spanMinutes > 0 ? spanMinutes : 1;
    final labels = <({int tickMinutes, double ideal, double width})>[];
    for (final tick in ticks) {
      final text = _formatHourAxisLabel(tick);
      labels.add((
        tickMinutes: tick,
        ideal: (tick - anchorMinutes) / span * gridWidthPx,
        width: _measureLabelWidth(context, text),
      ));
    }

    final lefts = List<double>.filled(labels.length, 0);
    lefts[0] = 0;

    for (var i = 1; i < labels.length; i++) {
      final prevRight = lefts[i - 1] + labels[i - 1].width;
      lefts[i] = labels[i].ideal > prevRight + _kHourLabelMinGap
          ? labels[i].ideal
          : prevRight + _kHourLabelMinGap;
    }

    final last = labels.length - 1;
    if (last > 0) {
      final maxLeft = trackWidthPx - labels[last].width;
      if (lefts[last] > maxLeft) {
        lefts[last] = maxLeft;
      }
      for (var i = last - 1; i >= 1; i--) {
        final maxLeftForI =
            lefts[i + 1] - labels[i].width - _kHourLabelMinGap;
        if (lefts[i] > maxLeftForI) {
          lefts[i] = maxLeftForI.toDouble();
        }
        final minLeftForI = i == 0
            ? 0.0
            : lefts[i - 1] + labels[i - 1].width + _kHourLabelMinGap;
        if (lefts[i] < minLeftForI) {
          lefts[i] = minLeftForI;
        }
      }
    }

    return [
      for (var i = 0; i < labels.length; i++)
        (tickMinutes: labels[i].tickMinutes, left: lefts[i]),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final ticks = _buildSchoolHourTicks(
      startMinutes: anchorMinutes,
      endMinutes: axisEndMinutes,
    );
    final span = gridMinutes > 0 ? gridMinutes : 1;
    final trackWidth = gridWidthPx + endLabelReservePx;
    final placements = _layoutHourLabels(
      context: context,
      ticks: ticks,
      anchorMinutes: anchorMinutes,
      spanMinutes: span,
      gridWidthPx: gridWidthPx,
      trackWidthPx: trackWidth,
    );

    return SizedBox(
      width: trackWidth,
      height: 14,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final placement in placements)
            Positioned(
              left: placement.left,
              top: 0,
              child: Text(
                _formatHourAxisLabel(placement.tickMinutes),
                style: _labelStyle,
                maxLines: 1,
                softWrap: false,
              ),
            ),
        ],
      ),
    );
  }
}

List<int> _buildSchoolHourTicks({
  required int startMinutes,
  required int endMinutes,
}) {
  if (endMinutes <= startMinutes) return [startMinutes];

  final ticks = <int>[startMinutes];
  var hourMark = ((startMinutes ~/ 60) + 1) * 60;
  while (hourMark < endMinutes) {
    if (hourMark > startMinutes) ticks.add(hourMark);
    hourMark += 60;
  }
  if (ticks.last != endMinutes) ticks.add(endMinutes);
  return ticks;
}

/// One daily schedule row: fixed left label + scrollable coloured blocks.
class SchedulingDayGanttRow extends StatelessWidget {
  const SchedulingDayGanttRow({
    super.key,
    required this.left,
    required this.right,
  });

  final Widget left;
  final Widget right;

  static const Color dividerColor = Color(0xFFE9ECEF);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: dividerColor)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: kSchedulingDayLeftColumnWidth,
            child: left,
          ),
          Container(width: 1, color: dividerColor),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              child: ClipRect(
                child: right,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Classroom row: forecast ratio blocks (UNDER / IN / EXTRA from API).
class SchedulingClassroomDayTimeline extends StatefulWidget {
  const SchedulingClassroomDayTimeline({
    super.key,
    required this.slots,
    required this.slotDetails,
    required this.day,
    required this.classroomName,
    required this.dayStartMinutes,
    required this.dayEndMinutes,
    required this.slotMinutes,
    this.staffName,
  });

  final List<TimeSlotStatus> slots;
  final List<ForecastSlotDetail?> slotDetails;
  final DateTime day;
  final String classroomName;
  final int dayStartMinutes;
  final int dayEndMinutes;
  final int slotMinutes;
  final String? staffName;

  @override
  State<SchedulingClassroomDayTimeline> createState() =>
      _SchedulingClassroomDayTimelineState();
}

class _SchedulingClassroomDayTimelineState
    extends State<SchedulingClassroomDayTimeline> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return SchedulingDayTimelineTrack(
      slotCount: widget.slots.length,
      dayStartMinutes: widget.dayStartMinutes,
      dayEndMinutes: widget.dayEndMinutes,
      slotMinutes: widget.slotMinutes,
      emptyMessage: 'No schedule',
      blocks: [
        for (int i = 0; i < widget.slots.length; i++)
          _RatioSlotTapTarget(
            status: widget.slots[i],
            detail: i < widget.slotDetails.length
                ? widget.slotDetails[i]
                : null,
            isSelected: _selectedIndex == i,
            onTap: () {
              setState(() => _selectedIndex = i);
              _showSlotDetails(
                context,
                slotIndex: i,
                status: widget.slots[i],
                detail: i < widget.slotDetails.length
                    ? widget.slotDetails[i]
                    : null,
              );
            },
          ),
      ],
    );
  }

  void _showSlotDetails(
    BuildContext context, {
    required int slotIndex,
    required TimeSlotStatus status,
    ForecastSlotDetail? detail,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) => SchedulingSlotDetailsDialog(
        day: widget.day,
        slotIndex: slotIndex,
        classroomName: widget.classroomName,
        status: status,
        detail: detail,
        dayStartMinutes: widget.dayStartMinutes,
        slotMinutes: widget.slotMinutes,
        staffName: widget.staffName,
      ),
    ).then((_) {
      if (mounted) setState(() => _selectedIndex = null);
    });
  }
}

/// Staff row: work/break blocks from shift API across full school hours.
class SchedulingStaffDayTimeline extends StatefulWidget {
  const SchedulingStaffDayTimeline({
    super.key,
    required this.slots,
    required this.slotDetails,
    required this.day,
    required this.classroomName,
    required this.dayStartMinutes,
    required this.dayEndMinutes,
    required this.slotMinutes,
    required this.staffName,
  });

  final List<StaffShiftSlotStatus> slots;
  final List<StaffShiftSlotDetail?> slotDetails;
  final DateTime day;
  final String classroomName;
  final int dayStartMinutes;
  final int dayEndMinutes;
  final int slotMinutes;
  final String staffName;

  @override
  State<SchedulingStaffDayTimeline> createState() =>
      _SchedulingStaffDayTimelineState();
}

class _SchedulingStaffDayTimelineState extends State<SchedulingStaffDayTimeline> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    return SchedulingDayTimelineTrack(
      slotCount: widget.slots.length,
      dayStartMinutes: widget.dayStartMinutes,
      dayEndMinutes: widget.dayEndMinutes,
      slotMinutes: widget.slotMinutes,
      emptyMessage: 'No shift',
      blocks: [
        for (int i = 0; i < widget.slots.length; i++)
          _StaffSlotTapTarget(
            status: widget.slots[i],
            detail: i < widget.slotDetails.length
                ? widget.slotDetails[i]
                : null,
            isSelected: _selectedIndex == i,
            onTap: () {
              setState(() => _selectedIndex = i);
              _showStaffSlotDetails(
                context,
                slotIndex: i,
                detail: i < widget.slotDetails.length
                    ? widget.slotDetails[i]
                    : null,
              );
            },
          ),
      ],
    );
  }

  void _showStaffSlotDetails(
    BuildContext context, {
    required int slotIndex,
    StaffShiftSlotDetail? detail,
  }) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.25),
      builder: (_) => SchedulingStaffSlotDetailsDialog(
        day: widget.day,
        slotIndex: slotIndex,
        classroomName: widget.classroomName,
        staffName: widget.staffName,
        detail: detail,
        dayStartMinutes: widget.dayStartMinutes,
        slotMinutes: widget.slotMinutes,
      ),
    ).then((_) {
      if (mounted) setState(() => _selectedIndex = null);
    });
  }
}

/// Placeholder slot so the blocks row width matches [layoutSlotCount] × stride.
class _EmptyTimelineSlot extends StatelessWidget {
  const _EmptyTimelineSlot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: kDayTimelineSlotHPad,
        vertical: kDayTimelineSlotVPad,
      ),
      child: SizedBox(
        width: kDayTimelineBlockSize,
        height: kDayTimelineBlockSize,
      ),
    );
  }
}

class _RatioSlotTapTarget extends StatelessWidget {
  const _RatioSlotTapTarget({
    required this.status,
    required this.detail,
    required this.onTap,
    this.isSelected = false,
  });

  final TimeSlotStatus status;
  final ForecastSlotDetail? detail;
  final VoidCallback onTap;
  final bool isSelected;

  String? get _hoverMessage {
    if (detail == null || !detail!.hasForecastData) return null;
    return 'Expected students: ${detail!.expectedStudents}\n'
        'Required staff: ${detail!.requiredStaff}\n'
        'Scheduled staff: ${detail!.scheduledStaff}';
  }

  @override
  Widget build(BuildContext context) {
    final block = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDayTimelineSlotHPad,
          vertical: kDayTimelineSlotVPad,
        ),
        child: Container(
          width: kDayTimelineBlockSize,
          height: kDayTimelineBlockSize,
          decoration: BoxDecoration(
            color: SchedulingBlockStatusStyle.daySlotColor(status),
            borderRadius: BorderRadius.circular(3),
            border: isSelected
                ? Border.all(color: AppColors.primaryColor, width: 1.5)
                : null,
          ),
        ),
      ),
    );

    final message = _hoverMessage;
    if (message == null) return block;

    return Tooltip(
      message: message,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 300),
      child: block,
    );
  }
}

class _StaffSlotTapTarget extends StatelessWidget {
  const _StaffSlotTapTarget({
    required this.status,
    required this.detail,
    required this.onTap,
    this.isSelected = false,
  });

  final StaffShiftSlotStatus status;
  final StaffShiftSlotDetail? detail;
  final VoidCallback onTap;
  final bool isSelected;

  String? get _hoverMessage {
    if (status == StaffShiftSlotStatus.empty || detail == null) return null;
    if (!detail!.hasShiftData) return null;
    final lines = <String>[SchedulingStaffShiftStyle.slotLabel(status)];
    if (detail!.shiftStart != null && detail!.shiftEnd != null) {
      lines.add(
        'Shift: ${_formatTime(detail!.shiftStart!)} - ${_formatTime(detail!.shiftEnd!)}',
      );
    }
    if (detail!.breakStart != null && detail!.breakEnd != null) {
      lines.add(
        'Break: ${_formatTime(detail!.breakStart!)} - ${_formatTime(detail!.breakEnd!)}',
      );
    }
    return lines.join('\n');
  }

  static String _formatTime(TimeOfDay t) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final mm = t.minute.toString().padLeft(2, '0');
    final ap = t.hour < 12 ? 'AM' : 'PM';
    return '$h12:$mm $ap';
  }

  @override
  Widget build(BuildContext context) {
    final block = GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: kDayTimelineSlotHPad,
          vertical: kDayTimelineSlotVPad,
        ),
        child: Container(
          width: kDayTimelineBlockSize,
          height: kDayTimelineBlockSize,
          decoration: BoxDecoration(
            color: SchedulingStaffShiftStyle.slotColor(status),
            borderRadius: BorderRadius.circular(3),
            border: isSelected
                ? Border.all(color: AppColors.primaryColor, width: 1.5)
                : null,
          ),
        ),
      ),
    );

    final message = _hoverMessage;
    if (message == null) return block;

    return Tooltip(
      message: message,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 300),
      child: block,
    );
  }
}

/// Staff shift slot details (work/break — not forecast ratio).
class SchedulingStaffSlotDetailsDialog extends StatelessWidget {
  const SchedulingStaffSlotDetailsDialog({
    super.key,
    required this.day,
    required this.slotIndex,
    required this.classroomName,
    required this.staffName,
    required this.detail,
    required this.dayStartMinutes,
    required this.slotMinutes,
  });

  final DateTime day;
  final int slotIndex;
  final String classroomName;
  final String staffName;
  final StaffShiftSlotDetail? detail;
  final int dayStartMinutes;
  final int slotMinutes;

  @override
  Widget build(BuildContext context) {
    final slot = slotMinutes > 0 ? slotMinutes : _kDefaultSlotMinutes;
    final anchor =
        dayStartMinutes > 0 ? dayStartMinutes : _kDefaultDayStartMinutes;
    final startMin = anchor + slotIndex * slot;
    final slotStart = TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60);
    final endMin = startMin + slot;
    final slotEnd = TimeOfDay(hour: endMin ~/ 60, minute: endMin % 60);

    final status = detail?.status ?? StaffShiftSlotStatus.empty;
    final label = SchedulingStaffShiftStyle.slotLabel(status);

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
              Text(
                DateFormat('EEEE, MMM d, yyyy').format(day),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$classroomName · $staffName',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  color: AppColors.primaryColor.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SchedulingStaffShiftStyle.slotColor(status),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Block: ${_formatTime(slotStart)} - ${_formatTime(slotEnd)}',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
              ),
              if (detail?.shiftStart != null && detail?.shiftEnd != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Shift hours: ${_formatTime(detail!.shiftStart!)} - '
                  '${_formatTime(detail!.shiftEnd!)}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
              if (detail?.breakStart != null && detail?.breakEnd != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Break: ${_formatTime(detail!.breakStart!)} - '
                  '${_formatTime(detail!.breakEnd!)}',
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    color: AppColors.primaryColor,
                  ),
                ),
              ],
              if (detail != null && detail!.isPublished) ...[
                const SizedBox(height: 8),
                Text(
                  'Published shift',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: AppColors.primaryColor.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final mm = t.minute.toString().padLeft(2, '0');
    final ap = t.hour < 12 ? 'AM' : 'PM';
    return '$h12:$mm $ap';
  }
}

/// Tap / hover detail panel for one monitoring block (PRD acceptance criteria).
class SchedulingSlotDetailsDialog extends StatelessWidget {
  const SchedulingSlotDetailsDialog({
    super.key,
    required this.day,
    required this.slotIndex,
    required this.classroomName,
    required this.status,
    required this.detail,
    required this.dayStartMinutes,
    required this.slotMinutes,
    this.staffName,
  });

  final DateTime day;
  final int slotIndex;
  final String classroomName;
  final TimeSlotStatus status;
  final ForecastSlotDetail? detail;
  final int dayStartMinutes;
  final int slotMinutes;
  final String? staffName;

  @override
  Widget build(BuildContext context) {
    final slot = slotMinutes > 0 ? slotMinutes : _kDefaultSlotMinutes;
    final anchor =
        dayStartMinutes > 0 ? dayStartMinutes : _kDefaultDayStartMinutes;
    final startMin = anchor + slotIndex * slot;
    final fallbackStart =
        TimeOfDay(hour: startMin ~/ 60, minute: startMin % 60);
    final fallbackEndMin = startMin + slot;
    final fallbackEnd = TimeOfDay(
      hour: fallbackEndMin ~/ 60,
      minute: fallbackEndMin % 60,
    );

    final hasForecast = detail?.hasForecastData ?? false;
    final start = hasForecast && detail!.blockStart != null
        ? detail!.blockStart!
        : fallbackStart;
    final end =
        hasForecast && detail!.blockEnd != null ? detail!.blockEnd! : fallbackEnd;

    final kind = hasForecast
        ? detail!.statusKind
        : SchedulingBlockStatusStyle.fromTimeSlotStatus(status);
    final counts = _countsFromDetail(detail, hasForecast);
    final badge = hasForecast
        ? detail!.ratioBadgeLabel
        : SchedulingBlockStatusStyle.ratioBadgeLabel(kind);
    final badgeColor = SchedulingBlockStatusStyle.badgeColorForKind(kind);
    final monitoringMessage = _monitoringMessage(detail, hasForecast);

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
                        textAlign: TextAlign.end,
                      ),
                      if (staffName != null && staffName!.trim().isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          staffName!,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color:
                                AppColors.primaryColor.withValues(alpha: 0.65),
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ],
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor,
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
              if (monitoringMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  monitoringMessage,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: AppColors.primaryColor.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(TimeOfDay t) {
    final h12 = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final mm = t.minute.toString().padLeft(2, '0');
    final ap = t.hour < 12 ? 'AM' : 'PM';
    return '$h12:$mm $ap';
  }

  String? _monitoringMessage(ForecastSlotDetail? d, bool hasForecast) {
    if (d != null && hasForecast) {
      return d.withinMonitoringWindow
          ? 'This block is inside the monitoring window and counts toward daily compliance.'
          : 'This block is outside the monitoring window. It does not affect daily compliance.';
    }
    if (status == TimeSlotStatus.empty) {
      return 'No forecast data for this time block.';
    }
    return null;
  }

  _SlotCounts _countsFromDetail(ForecastSlotDetail? d, bool hasForecast) {
    if (d != null && hasForecast) {
      return _SlotCounts(
        expected: d.expectedStudents,
        required: d.requiredStaff,
        scheduled: d.scheduledStaff,
      );
    }
    return const _SlotCounts(expected: 0, required: 0, scheduled: 0);
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
