import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/common/widgets/custom_date_time_field.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';

/// Photo + name (+ optional subtitle) header card shown atop
/// student_edit_attendance_form.dart and staff_edit_attendance_form.dart —
/// was two near-identical private methods (`_buildStudentHeaderCard` /
/// `_buildStaffHeaderCard`), differing only in which field fed the subtitle
/// (room name, always shown, vs. designation, shown only when present).
class AttendanceEditHeaderCard extends StatelessWidget {
  const AttendanceEditHeaderCard({
    super.key,
    required this.photoUuid,
    required this.name,
    this.subtitle,
  });

  final String? photoUuid;
  final String name;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return CustomSectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.xxs),
          ProfileAvatar(name: name, size: 36, fontSize: 14),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.value(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null && subtitle!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  AppText.small(
                    subtitle!,
                    style: AppTextStyles.small.copyWith(
                      color: AppColors.secondaryColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Labeled time picker used twice (sign-in / sign-out) in both edit-attendance
/// forms — was an identical private `_buildTimeSection` method in both.
class AttendanceEditTimeSection extends StatelessWidget {
  const AttendanceEditTimeSection({
    super.key,
    required this.label,
    required this.time,
    required this.onTimeChanged,
  });

  final String label;
  final TimeOfDay? time;
  final ValueChanged<TimeOfDay> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.label(label),
        const SizedBox(height: AppSpacing.xs),
        CustomDateTimeField(
          isTime: true,
          initialTime: time,
          onTimeSelected: onTimeChanged,
        ),
      ],
    );
  }
}
