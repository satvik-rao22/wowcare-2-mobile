import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../app/theme/colors.dart';
import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/profile_show_widget.dart';
import '../model/scheduling_models.dart';

/// Drop trailing `.0` so whole hours render as `9h` not `9.0h`, but fractional
/// values (e.g. 7.5h) keep their decimal.
String formatSchedulingHours(double hours) {
  if (hours == hours.truncateToDouble()) return hours.toInt().toString();
  return hours.toStringAsFixed(1);
}

/// Day-view left column: image, name, optional subtitle / hour chips (stacked).
class SchedulingEntityLeftCell extends StatelessWidget {
  const SchedulingEntityLeftCell({
    super.key,
    required this.title,
    required this.imageFileUuid,
    this.mediaAssetCode,
    this.staffCode,
    this.placeholderAsset,
    this.subtitle,
    this.availableHours,
    this.scheduledHours,
    this.unscheduledHours,
    this.showHours = false,
    this.statusColor,
    this.statusTooltip,
  });

  final String title;
  final String imageFileUuid;
  final String? mediaAssetCode;
  final String? staffCode;
  final String? placeholderAsset;
  final String? subtitle;
  final double? availableHours;
  final double? scheduledHours;
  final double? unscheduledHours;
  final bool showHours;

  /// Pre-resolved status dot color (e.g. green for SIGNED_IN, red for ABSENT)
  /// — bypasses [DocumentImageWidget]'s built-in per-staff attendance API call
  /// in favor of a bulk lookup done at the screen level.
  final Color? statusColor;
  final String? statusTooltip;

  static const TextStyle _nameStyle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryColor,
  );

  static final TextStyle _subtitleStyle = TextStyle(
    fontFamily: 'Manrope',
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.primaryColor.withValues(alpha: 0.65),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
          children: [
            DocumentImageWidget(
              fileUuid: imageFileUuid,
              name: title,
              mediaAssetCode: mediaAssetCode,
              staffCode: staffCode,
              size: 38,
              placeholderAsset: placeholderAsset ?? MediaRes.classroomIcon,
              disableProfileLookupFallback: mediaAssetCode != null &&
                  mediaAssetCode!.trim().isNotEmpty,
              disableAttendanceStatusLookup: true,
              statusColor: statusColor,
              statusTooltip: statusTooltip,
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: _nameStyle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (subtitle != null && subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: _subtitleStyle,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (showHours &&
                availableHours != null &&
                scheduledHours != null &&
                unscheduledHours != null) ...[
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: _HoursBadge(
                  availableHours: availableHours!,
                  scheduledHours: scheduledHours!,
                  unscheduledHours: unscheduledHours!,
                ),
              ),
            ],
          ],
      ),
    );
  }
}

/// Classroom row: logo → name → "Class Schedule".
class ClassroomRowLeft extends StatelessWidget {
  const ClassroomRowLeft({
    super.key,
    required this.classroomCode,
    required this.classroomName,
  });

  final String classroomCode;
  final String classroomName;

  @override
  Widget build(BuildContext context) {
    return SchedulingEntityLeftCell(
      title: classroomName,
      imageFileUuid: classroomCode,
      placeholderAsset: MediaRes.classroomIcon,
      subtitle: 'Class Schedule',
    );
  }
}

/// Maps a today's sign-in status string from the bulk
/// `/staff-attendance/sign-in/status` endpoint to the dot color used on the
/// scheduling screens. SIGNED_IN → green, ABSENT → red, anything else → null
/// (the avatar shows no dot).
Color? schedulingAttendanceDotColor(String? status) {
  final normalized = (status ?? '').trim().toUpperCase();
  if (normalized.isEmpty) return null;
  if (normalized == 'SIGNED_IN' || normalized == 'SIGNED-IN') {
    return const Color.fromRGBO(0, 177, 21, 1);
  }
  if (normalized == 'ABSENT') return Colors.red;
  return null;
}

String? schedulingAttendanceDotTooltip(String? status) {
  final normalized = (status ?? '').trim().toUpperCase();
  if (normalized == 'SIGNED_IN' || normalized == 'SIGNED-IN') return 'Signed in';
  if (normalized == 'ABSENT') return 'Absent';
  return null;
}

/// Staff row: photo → name → three hour chips on one line.
class StaffRowLeft extends StatelessWidget {
  const StaffRowLeft({
    super.key,
    required this.entry,
    this.attendanceStatus,
  });

  final StaffScheduleEntry entry;

  /// Today's sign-in status for this staff, resolved by the screen via the
  /// bulk `/staff-attendance/sign-in/status` POST. Drives the avatar dot.
  final String? attendanceStatus;

  @override
  Widget build(BuildContext context) {
    final code = entry.staffCode.trim();
    return SchedulingEntityLeftCell(
      title: entry.staffName,
      imageFileUuid: code.isNotEmpty ? code : entry.staffName,
      mediaAssetCode: entry.profilePhotoAssetCode,
      staffCode: code.isNotEmpty ? code : null,
      availableHours: entry.availableHours,
      scheduledHours: entry.scheduledHours,
      unscheduledHours: entry.unscheduledHours,
      showHours: true,
      statusColor: schedulingAttendanceDotColor(attendanceStatus),
      statusTooltip: schedulingAttendanceDotTooltip(attendanceStatus),
    );
  }
}

class _HoursBadge extends StatelessWidget {
  const _HoursBadge({
    required this.availableHours,
    required this.scheduledHours,
    required this.unscheduledHours,
  });

  final double availableHours;
  final double scheduledHours;
  final double unscheduledHours;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _HourChip(
          iconAsset: MediaRes.availableHoursIcon,
          hours: availableHours,
        ),
        const SizedBox(width: 5),
        _HourChip(
          iconAsset: MediaRes.scheduledHoursIcon,
          hours: scheduledHours,
        ),
        const SizedBox(width: 5),
        _HourChip(
          iconAsset: MediaRes.unScheduledHoursIcon,
          hours: unscheduledHours,
        ),
      ],
    );
  }
}

class _HourChip extends StatelessWidget {
  const _HourChip({required this.iconAsset, required this.hours});

  final String iconAsset;
  final double hours;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(iconAsset, width: 13, height: 13),
        const SizedBox(width: 2),
        Text(
          '${formatSchedulingHours(hours)}h',
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.primaryColor,
          ),
        ),
      ],
    );
  }
}

/// Right-cell content for a staff row: time-range pill with a solid border
/// for published shifts and a dotted border for drafts.
class StaffTimeRangePill extends StatelessWidget {
  const StaffTimeRangePill({
    super.key,
    required this.startTime,
    required this.endTime,
    this.isPublished = false,
    this.onTap,
  });

  final String startTime;
  final String endTime;
  final bool isPublished;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const borderColor = Color(0xFF89A0FF);
    const radius = 8.0;
    final inner = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(radius),
        border: isPublished
            ? Border.all(color: borderColor, width: 1.2)
            : null,
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
    );

    final pill = isPublished
        ? inner
        : CustomPaint(
            foregroundPainter: _DashedRRectPainter(
              color: borderColor,
              strokeWidth: 1.2,
              radius: radius,
            ),
            child: inner,
          );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      child: onTap == null
          ? pill
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(radius),
                child: pill,
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
