import 'package:intl/intl.dart';

import '../../../../domain/features/staff/entities/staff_shift.dart';
import '../models/staff_models.dart';
import '../models/staff_shift_models.dart';

class StaffShiftMapper {
  const StaffShiftMapper._();

  static String _toShiftClockString(StaffProfileTimeModel time) {
    final period = time.hour >= 12 ? 'PM' : 'AM';
    final displayHour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final displayMinute = time.minute.toString().padLeft(2, '0');
    final displaySecond = time.second.toString().padLeft(2, '0');
    return '${displayHour.toString().padLeft(2, '0')}:'
        '$displayMinute:$displaySecond $period';
  }

  static bool _hasMeaningfulTime(StaffProfileTimeModel? time) {
    if (time == null) return false;
    return time.hour != 0 || time.minute != 0 || time.second != 0;
  }

  static StaffShiftDaySummary toDaySummary(
    StaffShiftsPageModel page, {
    String fallbackRoomLabel = '',
  }) {
    if (page.items.isEmpty) {
      return StaffShiftDaySummary.empty;
    }

    final first = page.items.first;
    final blocks = <StaffShiftTimelineBlock>[];

    for (final item in page.items) {
      final room = item.classroomCode.trim().isNotEmpty
          ? item.classroomCode.trim()
          : fallbackRoomLabel;

      if (_hasMeaningfulTime(item.startTime) && _hasMeaningfulTime(item.endTime)) {
        blocks.add(
          StaffShiftTimelineBlock(
            room: room,
            start: _toShiftClockString(item.startTime),
            end: _toShiftClockString(item.endTime),
          ),
        );
      }

      if (_hasMeaningfulTime(item.breakStartTime) &&
          _hasMeaningfulTime(item.breakEndTime)) {
        blocks.add(
          StaffShiftTimelineBlock(
            room: 'Lunch Break',
            start: _toShiftClockString(item.breakStartTime!),
            end: _toShiftClockString(item.breakEndTime!),
            isBreak: true,
          ),
        );
      }
    }

    return StaffShiftDaySummary(
      availableHours: first.availableHours,
      scheduledHours: first.scheduledHours,
      unscheduledHours: first.unscheduledHours,
      blocks: blocks,
    );
  }

  static String formatApiDate(DateTime date) =>
      DateFormat('yyyy-MM-dd').format(
        DateTime(date.year, date.month, date.day),
      );
}
