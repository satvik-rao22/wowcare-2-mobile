import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

/// Shared search input for the attendance selection forms: a borderless
/// [TextField] with a leading search icon inside a rounded, grey-bordered white
/// container. Extracted verbatim from 8 identical copies across the student/staff
/// selection forms (Task 07 / Mandate 6) — renders pixel-for-pixel the same.
///
/// Sites that drive search via a controller listener pass [onChanged] as null
/// (the listener still fires); sites that reload inline pass an [onChanged].
class AttendanceSearchField extends StatelessWidget {
  const AttendanceSearchField({
    super.key,
    required this.controller,
    required this.hintText,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(AppRadius.r15),
        border: Border.all(color: AppColors.attendanceMutedTextColor),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: AppTextStyles.body.copyWith(
            color: AppColors.attendanceSearchHintColor,
          ),
          border: InputBorder.none,
          icon: const Icon(
            Icons.search,
            color: AppColors.attendanceMutedTextColor,
          ),
        ),
      ),
    );
  }
}
