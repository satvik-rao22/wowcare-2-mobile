import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

import '../forms/staff_attendance_forms/staff_entity.dart';

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
              ? const Color.fromARGB(255, 249, 245, 250)
              : Colors.white,
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
              DocumentImageWidget(
                fileUuid: staff.photoUuid ?? '',
                name: staff.name,
                staffCode: staff.staffCode,
                showOnlyAbsentAttendanceDot: showOnlyAbsentAttendanceDot,
                size: 32,
                fontSize: 14,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: EllipsisTooltipText(
                  text: staff.name,
                  maxLines: 2,
                  preferLongPress: true,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
