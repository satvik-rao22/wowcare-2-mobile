import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/simmer_loader.dart';
import 'package:wowcare/core/theme/app_icon.dart';

/// Small circular value badge (e.g. "5h", "30m") used inside the attendance
/// profile stat rows — shared by the student and staff profile screens, was
/// an identical private `_buildValueCircle` in both.
class AttendanceProfileValueCircle extends StatelessWidget {
  const AttendanceProfileValueCircle({
    super.key,
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Center(
        child: AppText.body(
          text,
          style: AppTextStyles.body.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ),
    );
  }
}

/// A bordered stat row: icon, label, and a colored value circle — shared by
/// the student and staff profile screens, was an identical private
/// `_buildStatItem` in both.
class AttendanceProfileStatItem extends StatelessWidget {
  const AttendanceProfileStatItem({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String icon;
  final Color iconColor;
  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.s10,
        horizontal: 15,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.attendanceCardBorderColor,
          width: 1,
        ),
        borderRadius: AppRadius.allMd,
      ),
      child: Row(
        children: [
          AppIcon(icon, height: 22, color: iconColor),
          const SizedBox(width: AppSpacing.xs),
          AppText.body(label, style: AppTextStyles.valueLarge),
          const Spacer(),
          AttendanceProfileValueCircle(text: value, color: valueColor),
        ],
      ),
    );
  }
}

/// The "Attended Hours" stat row, parsed from a raw "5 Hrs 30 Mins"-shaped
/// string — shared by the student and staff profile screens, was an
/// identical private `_buildAttendedHoursStat` in both (each originally took
/// its own file-private report model; generalized to the one string field it
/// actually read).
class AttendanceProfileAttendedHoursStat extends StatelessWidget {
  const AttendanceProfileAttendedHoursStat({
    super.key,
    required this.totalAttendedHours,
  });

  /// Raw "5 Hrs 30 Mins"-shaped string, or null/empty when unknown.
  final String? totalAttendedHours;

  @override
  Widget build(BuildContext context) {
    int hours = 0;
    int minutes = 0;

    final raw = totalAttendedHours;
    if (raw != null && raw.isNotEmpty) {
      final parts = raw.split(' ');
      if (parts.length >= 4) {
        hours = int.tryParse(parts[0]) ?? 0;
        minutes = int.tryParse(parts[2]) ?? 0;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.s10,
        horizontal: 15,
      ),
      decoration: BoxDecoration(
        border: Border.all(
          color: AppColors.attendanceCardBorderColor,
          width: 1,
        ),
        borderRadius: AppRadius.allMd,
      ),
      child: Row(
        children: [
          AppIcon(
            MediaRes.timerIcon,
            height: 22,
            color: AppColors.attendanceStatBlueColor,
          ),
          const SizedBox(width: AppSpacing.xs),
          const AppText.body('Attended Hours', style: AppTextStyles.valueLarge),
          const Spacer(),
          Row(
            children: [
              AttendanceProfileValueCircle(
                text: '${hours}h',
                color: AppColors.attendanceStatBlueColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              AttendanceProfileValueCircle(
                text: '${minutes}m',
                color: AppColors.attendanceStatBlueColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Loading placeholder for the attendance profile screen — shared by the
/// student and staff profile screens, was an identical private
/// `_buildAttendanceShimmer` in both.
class AttendanceProfileShimmer extends StatelessWidget {
  const AttendanceProfileShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ShimmerLoaderCard(
          child: Container(height: 300, width: double.infinity),
        ),
        ListView.builder(
          shrinkWrap: true,
          itemCount: 3,
          itemBuilder: (context, index) {
            return const ShimmerLoaderCard(child: SizedBox(height: 50));
          },
        ),
      ],
    );
  }
}
