import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/dashboard/view/widgets/my_shifts_card.dart';
import 'package:wowcare/presentation/features/scheduling/utils/classroom_name_resolver.dart';

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
  });

  final DailyShifts dailyRoomSchedule;
  final String dayColumnLabel;
  final ClassroomNameResolver? classroomResolver;

  /// School open time for the selected weekday (`hh:mm:ss a`).
  final String schoolStartTime;

  /// School close time for the selected weekday (`hh:mm:ss a`).
  final String schoolEndTime;

  @override
  State<StaffDayScheduleCalendar> createState() =>
      _StaffDayScheduleCalendarState();
}

class _StaffDayScheduleCalendarState extends State<StaffDayScheduleCalendar> {
  late final List<Shift> _shifts;

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
    final format = DateFormat('hh:mm:ss a');
    final start = format.parse(startTime);
    final end = format.parse(endTime);
    return end.difference(start).inMinutes / 60.0;
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

  Widget _buildSingleShift(Shift shift) {
    final roomLabel = _displayRoom(shift);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Text(
            roomLabel,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryColor,
            ),
            maxLines: 3,
            softWrap: true,
          ),
          const SizedBox(height: 8),
          Text(
            '${_convertTimeToHHmm(shift.start)} - ${_convertTimeToHHmm(shift.end)}',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 8),
      color: const Color.fromRGBO(254, 241, 199, 1),
      child: Text.rich(
        TextSpan(
          children: [
            const TextSpan(
              text: 'Lunch Break  ',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.black87,
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
              ),
            ),
          ],
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildTimeContainer(Shift shift) {
    final double height =
        _getTimeDifferenceInHours(shift.start, shift.end) * cellHeightRow;
    final double topSpace = _getTimeDifferenceInHours(
          widget.schoolStartTime,
          shift.start,
        ) *
        cellHeightRow;

    if (shift.isBreakShift) {
      return Positioned(
        top: topSpace,
        left: 0,
        right: 0,
        child: SizedBox(
          height: height,
          child: _buildBreakShift(shift),
        ),
      );
    }

    return Positioned(
      top: topSpace,
      left: 0,
      right: 0,
      child: SizedBox(
        height: height,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: const Color.fromRGBO(234, 244, 255, 1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.themeColor.withValues(alpha: 0.15),
            ),
          ),
          child: _buildSingleShift(shift),
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
