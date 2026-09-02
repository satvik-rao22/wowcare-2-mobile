import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';
import 'package:wowcare/shared/common/widgets/ellipsis_tooltip_text.dart';
import 'package:wowcare/shared/common/widgets/profile_show_widget.dart';

/// Selectable grid tile (checkbox + avatar + name) shared by the student
/// selection forms (sign-in/sign-out/transfer/mark-absent). Deliberately
/// takes primitive fields rather than a `StudentEntity` — each selection
/// form's submit screen defines its own local `StudentEntity` class, so a
/// shared widget can't depend on any single one of them.
class AttendanceSelectablePersonTile extends StatelessWidget {
  const AttendanceSelectablePersonTile({
    super.key,
    required this.name,
    required this.photoUuid,
    required this.code,
    required this.isSelected,
    required this.onSelectionChanged,
    this.showOnlyAbsentAttendanceDot = false,
  });

  final String name;
  final String photoUuid;
  final String code;
  final bool isSelected;
  final ValueChanged<bool?> onSelectionChanged;

  /// Only the sign-in list wants the absent-only attendance dot on the
  /// avatar; the other forms leave it at the widget's default.
  final bool showOnlyAbsentAttendanceDot;

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
              DocumentImageWidget(
                fileUuid: photoUuid,
                name: name,
                studentCode: code,
                showOnlyAbsentAttendanceDot: showOnlyAbsentAttendanceDot,
                size: 32,
                fontSize: 14,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: EllipsisTooltipText(
                  text: name,
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
