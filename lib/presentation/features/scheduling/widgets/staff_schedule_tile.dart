import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import '../model/scheduling_models.dart';

/// Left-cell content for a staff row in the schedule table: avatar, name,
/// and the scheduled/available hours badge.
class StaffRowLeft extends StatelessWidget {
  const StaffRowLeft({super.key, required this.entry});

  final StaffScheduleEntry entry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: Row(
        children: [
          DocumentImageWidget(
            fileUuid: entry.staffName,
            name: entry.staffName,
            imageUrl: entry.photoUrl,
            size: 38,
            disableProfileLookupFallback: true,
            disableAttendanceStatusLookup: true,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.staffName,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _HoursBadge(
                  scheduledHours: entry.scheduledHours,
                  availableHours: entry.availableHours,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HoursBadge extends StatelessWidget {
  const _HoursBadge({
    required this.scheduledHours,
    required this.availableHours,
  });

  final int scheduledHours;
  final int availableHours;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(MediaRes.scheduledHoursIcon, width: 16, height: 16),
        const SizedBox(width: 4),
        Text(
          '${scheduledHours}h',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 1,
          height: 14,
          color: AppColors.primaryColor.withValues(alpha: 0.25),
        ),
        const SizedBox(width: 8),
        Text(
          '${availableHours}h',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}

/// Right-cell content for a staff row: dashed-border time-range pill.
class StaffTimeRangePill extends StatelessWidget {
  const StaffTimeRangePill({
    super.key,
    required this.startTime,
    required this.endTime,
  });

  final String startTime;
  final String endTime;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: CustomPaint(
        foregroundPainter: _DashedRRectPainter(
          color: const Color(0xFF89A0FF),
          strokeWidth: 1.2,
          radius: 8,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.fieldBackgroundColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$startTime -\n$endTime',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryColor,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedRRectPainter extends CustomPainter {
  _DashedRRectPainter({
    required this.color,
    required this.strokeWidth,
    required this.radius,
  });

  final Color color;
  final double strokeWidth;
  final double radius;
  static const double dashLength = 5;
  static const double gapLength = 3;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(radius),
    );
    final path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final double end = (distance + dashLength).clamp(0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance = end + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedRRectPainter old) =>
      old.color != color ||
      old.strokeWidth != strokeWidth ||
      old.radius != radius;
}
