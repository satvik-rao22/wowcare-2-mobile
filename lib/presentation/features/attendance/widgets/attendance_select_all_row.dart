import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/common/widgets/custom_checkbox.dart';

/// "Select All" checkbox row shared by every attendance selection form
/// (student and staff sign-in/sign-out/transfer/mark-absent).
class AttendanceSelectAllRow extends StatelessWidget {
  const AttendanceSelectAllRow({
    super.key,
    required this.isChecked,
    required this.onChanged,
  });

  final bool isChecked;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
          child: CustomCheckbox(
            value: isChecked,
            onChanged: onChanged,
            borderColor: AppColors.themeColor,
          ),
        ),
        const AppText.body('Select All'),
      ],
    );
  }
}
