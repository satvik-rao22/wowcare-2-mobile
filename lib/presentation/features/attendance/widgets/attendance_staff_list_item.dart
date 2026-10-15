import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/profile_avatar.dart';
import 'package:wowcare/shared/common/widgets/attendance_status_dot.dart';

import '../model/staff_entity.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';

/// Selectable staff row shared by the staff-attendance selection forms
/// (sign-in, sign-out, transfer, mark-absent).
class AttendanceStaffListItem extends StatelessWidget {
  final StaffEntity staff;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  /// Sign-in is the only form that needs the avatar's attendance dot to
  /// reflect absence only (rather than the default sign-in/out state).
  final bool showOnlyAbsentAttendanceDot;

  const AttendanceStaffListItem({
    super.key,
    required this.staff,
    required this.isSelected,
    required this.onSelectionChanged,
    this.showOnlyAbsentAttendanceDot = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onSelectionChanged(!isSelected),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.themeColor),
          borderRadius: AppRadius.allSm,
          color: isSelected
              ? AppColors.attendanceSelectedTintColor
              : AppColors.cardColor,
        ),
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xxs),
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: CustomCheckbox(
                  borderColor: AppColors.themeColor,
                  value: isSelected,
                  onChanged: onSelectionChanged,
                ),
              ),
              ProfileAvatar(
                name: staff.name,
                staffCode: staff.staffCode,
                size: 32,
                fontSize: 14,
                statusDot: AttendanceStatusDot(
                  staffCode: staff.staffCode,
                  onlyAbsent: showOnlyAbsentAttendanceDot,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: EllipsisTooltipText(
                  text: staff.name,
                  maxLines: 2,
                  preferLongPress: true,
                  style: AppTextStyles.sectionHeader,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
