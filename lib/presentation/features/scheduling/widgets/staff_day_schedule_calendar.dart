import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_shifts_card.dart';
import 'package:wowcare/presentation/features/scheduling/utils/classroom_name_resolver.dart';
import 'package:wowcare/shared/common/widgets/highlightable_card.dart';

/// Day shift calendar for [StaffSchedulingScreen]: hourly time column plus
/// positioned shift blocks. The day column label is supplied by the parent
/// (single-day view); no in-calendar date navigation.
class StaffDayScheduleCalendar extends StatefulWidget {
  const StaffDayScheduleCalendar({
    super.key,
    required this.dailyRoomSchedule,
    required this.dayColumnLabel,
    required this.schoolStartTime,
    required this.schoolEndTime,
    this.classroomResolver,
    this.onShiftTap,
    this.highlightShiftCode,
  });

  final DailyShifts dailyRoomSchedule;
  final String dayColumnLabel;
  final ClassroomNameResolver? classroomResolver;

  /// Notification deep-link: the work-shift block whose `shiftCode` matches this
  /// scrolls into view and flashes.
  final String? highlightShiftCode;

  /// School open time for the selected weekday (`hh:mm:ss a`).
  final String schoolStartTime;

  /// School close time for the selected weekday (`hh:mm:ss a`).
  final String schoolEndTime;

  /// Fires when the user taps a non-break shift block. Break blocks are not
  /// considered an editable shift, so they ignore taps.
  final ValueChanged<Shift>? onShiftTap;

  @override
  State<StaffDayScheduleCalendar> createState() =>
      _StaffDayScheduleCalendarState();
}

class _StaffDayScheduleCalendarState extends State<StaffDayScheduleCalendar> {
  late List<Shift> _shifts;

  @override
  void initState() {
    super.initState();
    _shifts = List<Shift>.of(widget.dailyRoomSchedule.shifts)
      ..sort((a, b) {
        if (a.isBreakShift == b.isBreakShift) return 0;
        return a.isBreakShift ? 1 : -1;
      });
  }

  @override
  void didUpdateWidget(StaffDayScheduleCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    final scheduleChanged =
        oldWidget.dailyRoomSchedule != widget.dailyRoomSchedule;
    final hoursChanged = oldWidget.schoolStartTime != widget.schoolStartTime ||
        oldWidget.schoolEndTime != widget.schoolEndTime;
    if (scheduleChanged) {
      _shifts = List<Shift>.of(widget.dailyRoomSchedule.shifts)
        ..sort((a, b) {
          if (a.isBreakShift == b.isBreakShift) return 0;
          return a.isBreakShift ? 1 : -1;
        });
    } else if (hoursChanged) {
      setState(() {});
    }
  }

  DateTime _parseTime(String input) {
    const formats = ['h.mm a', 'hh:mm:ss a', 'hh:mm a'];
    for (final pattern in formats) {
      try {
        return DateFormat(pattern).parseStrict(input);
      } catch (_) {}
    }
    throw FormatException('Invalid time format: $input');
  }

  String _convertTimeToHHmm(String timeStr) {
    final dateTime = DateFormat('hh:mm:ss a').parse(timeStr);
    return DateFormat('hh:mm a').format(dateTime);
  }

  double _getTimeDifferenceInHours(String startTime, String endTime) {
    final start = _parseTime(startTime);
    final end = _parseTime(endTime);
    return end.difference(start).inMinutes / 60.0;
  }

  /// Returns the school start rounded DOWN to the hour, formatted as
  /// `hh:mm:ss a`. The hourly time-slot column is built from this rounded
  /// value (so a school opening at 8:30 still shows the "8:00 AM" row), so
  /// every shift block must measure its `topSpace` from the same anchor —
  /// otherwise a 9:30 shift gets painted half a row too high.
  String _slotGridStartLabel() {
    final raw = _parseTime(widget.schoolStartTime);
    final rounded = DateTime(raw.year, raw.month, raw.day, raw.hour);
    return DateFormat('hh:mm:ss a').format(rounded);
  }

  List<String> _generateHourlyTimeSlots(String start, String end) {
    final outputFormat = DateFormat('hh:mm a');
    DateTime startTime = _parseTime(start);
    DateTime endTime = _parseTime(end);

    startTime = DateTime(
      startTime.year,
      startTime.month,
      startTime.day,
      startTime.hour,
    );

    if (endTime.minute > 0 || endTime.second > 0) {
      endTime = endTime.add(const Duration(hours: 1));
      endTime =
          DateTime(endTime.year, endTime.month, endTime.day, endTime.hour);
    }

    final slots = <String>[];
    var current = startTime;
    while (current.isBefore(endTime)) {
      slots.add(outputFormat.format(current));
      current = current.add(const Duration(hours: 1));
    }
    return slots;
  }

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.07),
        border: const Border(
          bottom: BorderSide(width: 1, color: Colors.grey),
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const Expanded(
            flex: 3,
            child: Center(
              child: Text(
                'Time',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 5,
            child: Center(
              child: Text(
                widget.dayColumnLabel,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  color: AppColors.primaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeItem(String label) {
    return Container(
      height: cellHeightRow,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(width: 1, color: Colors.grey.shade300),
          right: BorderSide(width: 1, color: Colors.grey.shade300),
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'Manrope',
            color: AppColors.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeList() {
    final slots = _generateHourlyTimeSlots(
      widget.schoolStartTime,
      widget.schoolEndTime,
    );
    return Column(children: slots.map(_buildTimeItem).toList());
  }

  String _displayRoom(Shift shift) {
    if (shift.isBreakShift) return shift.room;
    return widget.classroomResolver?.resolveShiftRoom(shift.room) ??
        shift.room;
  }

  /// Returns the unobstructed vertical space at the top of a work-shift block,
  /// i.e. the height before any break overlay starts painting over it. For
  /// shifts with no internal break this is just the full block height; for a
  /// short shift containing a break it's the gap between the shift start and
  /// the break start. Drives the compact-layout switch in [_buildSingleShift].
  double _contentHeightAboveBreak(Shift workShift, double fullHeight) {
    final workStart = _parseTime(workShift.start);
    final workEnd = _parseTime(workShift.end);
    DateTime? firstBreakStart;
    for (final s in _shifts) {
      if (!s.isBreakShift) continue;
      final bStart = _parseTime(s.start);
      final bEnd = _parseTime(s.end);
      if (!bEnd.isAfter(workStart) || !bStart.isBefore(workEnd)) continue;
      if (firstBreakStart == null || bStart.isBefore(firstBreakStart)) {
        firstBreakStart = bStart;
      }
    }
    if (firstBreakStart == null) return fullHeight;
    final preBreakHours =
        firstBreakStart.difference(workStart).inMinutes / 60.0;
    if (preBreakHours <= 0) return 0;
    return preBreakHours * cellHeightRow;
  }

  Widget _buildSingleShift(Shift shift, double contentHeight) {
    final roomLabel = _displayRoom(shift);
    final timeLabel =
        '${_convertTimeToHHmm(shift.start)} - ${_convertTimeToHHmm(shift.end)}';

    // Short block: one row at the top, "Office · 4:10 PM - 5:30 PM". Used
    // when the visible content area (above any internal break overlay) is too
    // small to stack a title and time line without one of them being clipped
    // or covered by the break.
    if (contentHeight < 44) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                roomLabel,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.secondaryColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              timeLabel,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      );
    }

    // [Flexible] on the room label so the time row is never clipped when the
    // shift block is shorter than the natural content height (e.g. a 2nd
    // shift in a series often lands in a ≤1-hour cell): the room name
    // ellipsises before the time disappears.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              roomLabel,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.secondaryColor,
              ),
              maxLines: 2,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            timeLabel,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBreakShift(Shift shift) {
    return Container(
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: const Color.fromRGBO(254, 241, 199, 1),
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: '🍔  Lunch Break  ',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
            TextSpan(
              text:
                  '${_convertTimeToHHmm(shift.start)} - ${_convertTimeToHHmm(shift.end)}',
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
                height: 1.2,
              ),
            ),
          ],
        ),
        maxLines: 2,
        softWrap: true,
        overflow: TextOverflow.visible,
      ),
    );
  }

  Widget _buildTimeContainer(Shift shift) {
    final double height =
        _getTimeDifferenceInHours(shift.start, shift.end) * cellHeightRow;
    final double topSpace = _getTimeDifferenceInHours(
          _slotGridStartLabel(),
          shift.start,
        ) *
        cellHeightRow;

    if (shift.isBreakShift) {
      // Break uses [minHeight] (not a fixed height) so the yellow background
      // grows to cover the full wrapped label — a 30-min break is only ~20 px
      // tall on the grid, which can't fit "🍔 Lunch Break  04:30 PM - 05:05 PM"
      // on a single line, so the time portion wraps to a second line.
      return Positioned(
        top: topSpace,
        left: 0,
        right: 0,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: height),
          child: _buildBreakShift(shift),
        ),
      );
    }

    final contentHeight = _contentHeightAboveBreak(shift, height);
    final shiftWidget = Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(234, 244, 255, 1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.themeColor.withValues(alpha: 0.15),
        ),
      ),
      alignment: Alignment.topLeft,
      child: _buildSingleShift(shift, contentHeight),
    );

    // Flash + scroll-into-view when this block is the notification target.
    final highlightable = HighlightableCard(
      code: shift.shiftCode,
      highlightCode: widget.highlightShiftCode,
      scrollOnHighlight: true,
      borderRadius: 8,
      child: shiftWidget,
    );

    return Positioned(
      top: topSpace,
      left: 0,
      right: 0,
      child: SizedBox(
        height: height,
        child: shift.isBreakShift || widget.onShiftTap == null
            ? highlightable
            : GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onShiftTap!(shift),
                child: highlightable,
              ),
      ),
    );
  }

  Widget _buildShifts() {
    final slotCount = _generateHourlyTimeSlots(
      widget.schoolStartTime,
      widget.schoolEndTime,
    ).length;
    final workShifts =
        _shifts.where((s) => !s.isBreakShift).toList(growable: false);
    final breakShifts =
        _shifts.where((s) => s.isBreakShift).toList(growable: false);

    return SizedBox(
      height: cellHeightRow * slotCount,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            ...workShifts.map(_buildTimeContainer),
            ...breakShifts.map(_buildTimeContainer),
            if (_shifts.isEmpty)
              const Center(
                child: Text(
                  'No Shifts for Today',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 20,
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildTimeList()),
            Expanded(
              flex: 5,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: _buildShifts(),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
