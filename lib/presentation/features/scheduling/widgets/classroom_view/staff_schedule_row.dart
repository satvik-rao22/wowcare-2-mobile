import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:dotted_border/dotted_border.dart';
import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/media_res.dart';
import '../../../../../domain/features/staff_scheduling/entities/staff_shift.dart';

class StaffScheduleRow extends StatelessWidget {
  final StaffShiftEntity shift;
  final ScrollController controller;
  final List<String> timeLabels;

  const StaffScheduleRow({
    super.key,
    required this.shift,
    required this.controller,
    required this.timeLabels,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: const Color(0xFFF8F9FA),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(width: 160, child: _buildStaffInfo(shift)),
              const VerticalDivider(width: 1),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  controller: controller,
                  child: _buildTimelineRow(shift),
                ),
              ),
            ],
          ),
        ),
        const Divider(height: 1),
      ],
    );
  }

  Widget _buildStaffInfo(StaffShiftEntity shift) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 10, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primaryColor.withOpacity(0.1),
                child: Text(
                  shift.staffFirstName.isNotEmpty
                      ? shift.staffFirstName[0]
                      : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  shift.staffFullName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              SvgPicture.asset(
                MediaRes.availableHoursIcon,
                width: 14,
                height: 14,
              ),
              const SizedBox(width: 3),
              Text(
                '${shift.scheduledHours}h',
                style: const TextStyle(fontSize: 11),
              ),
              const SizedBox(width: 5),
              Container(width: 1, height: 12, color: AppColors.billingGrey),
              const SizedBox(width: 5),
              SvgPicture.asset(
                MediaRes.scheduledHoursIcon,
                width: 14,
                height: 14,
              ),
              const SizedBox(width: 3),
              Text(
                '${shift.availableHours}h',
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineRow(StaffShiftEntity shift) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(timeLabels.length, (index) {
              final color = _getSlotColor(timeLabels[index]);
              final isInShiftRange = color != Colors.transparent;
              final isPublished = _isPublishedShift();

              final baseSlot = Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                  border: isInShiftRange
                      ? (isPublished
                            ? Border.all(color: AppColors.themeColor, width: 1)
                            : null)
                      : Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox(
                  width: 30,
                  height: 30,
                  child: Center(
                    // child: (!isPublished && isInShiftRange)
                    //     ? DottedBorder(
                    //         options: RoundedRectDottedBorderOptions(
                    //           radius: const Radius.circular(6),
                    //           dashPattern: const [3, 2],
                    //           strokeWidth: 1,
                    //           color: AppColors.themeColor,
                    //         ),
                    //         child: baseSlot,
                    //       )
                    //     : baseSlot,
                    child: baseSlot,
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 6),
          Row(
            children: List.generate(timeLabels.length, (index) {
              String text = '';
              // Show label every 2 hours or for start/end
              if (index % 2 == 0 || index == timeLabels.length - 1) {
                text = timeLabels[index].split(' ')[0]; // Show only "07:00"
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: SizedBox(
                  width: 30,
                  child: Text(
                    text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 8, color: Colors.grey),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Color _getSlotColor(String label) {
    try {
      final slotTime = DateFormat('hh:mm a').parse(label);
      final shiftStart = _parseTime(shift.startTime);
      final shiftEnd = _parseTime(shift.endTime);

      if (!_isTimeInRange(slotTime, shiftStart, shiftEnd)) {
        return Colors.transparent;
      }

      // Check break time (Red)
      if (shift.breakStartTime != null && shift.breakEndTime != null) {
        final breakStart = _parseTime(shift.breakStartTime!);
        final breakEnd = _parseTime(shift.breakEndTime!);
        if (_isTimeInRange(slotTime, breakStart, breakEnd)) {
          return const Color(0xFFF38D8D); // light red
        }
      }

      // Check completed time (Blue)
      final now = DateTime.now();
      final shiftDate = DateFormat('yyyy-MM-dd').parse(shift.shiftDate);
      final today = DateTime(now.year, now.month, now.day);

      if (shiftDate.isBefore(today)) {
        return const Color(0xFF9BB7FF); // light blue
      } else if (shiftDate.isAtSameMomentAs(today)) {
        final currentTimeInMinutes = now.hour * 60 + now.minute;
        final slotTimeInMinutes = slotTime.hour * 60 + slotTime.minute;
        if (slotTimeInMinutes < currentTimeInMinutes) {
          return AppColors.colorBox; // light blue
        }
      }

      // Default scheduled work hours (Green)
      return const Color(0xFFACF3AA); // light green
    } catch (e) {
      return Colors.transparent;
    }
  }

  DateTime _parseTime(String timeStr) {
    // API returns "HH:mm:ss"
    return DateFormat('HH:mm:ss').parse(timeStr);
  }

  bool _isTimeInRange(DateTime time, DateTime start, DateTime end) {
    final t = time.hour * 60 + time.minute;
    final s = start.hour * 60 + start.minute;
    final e = end.hour * 60 + end.minute;
    return t >= s && t <= e;
  }

  bool _isPublishedShift() {
    final normalized = shift.shiftStatus.trim().toUpperCase();
    return normalized == 'PUBLISHED';
  }
}
