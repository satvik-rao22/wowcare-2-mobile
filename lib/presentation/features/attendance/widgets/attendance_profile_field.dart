import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_spacing.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/core/theme/app_icon.dart';

/// A label/value row used throughout the student and staff attendance
/// profile screens' expanded attendance/absence detail cards.
///
/// [methodIcon] is a pre-built icon rather than a shared enum — student and
/// staff attendance/absence-marking methods are genuinely different sets
/// (staff adds pin/transfer/nfc/biometric), so each screen keeps its own
/// enum-to-icon switch and just hands the built [Widget] in here.
class AttendanceProfileField extends StatelessWidget {
  const AttendanceProfileField({
    super.key,
    required this.label,
    required this.text,
    this.showTransferIcon = false,
    this.methodIcon,
  });

  final String label;
  final String text;
  final bool showTransferIcon;
  final Widget? methodIcon;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: AppTextStyles.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showTransferIcon) ...[
                Tooltip(
                  message: 'Transfer',
                  child: AppIcon(
                    MediaRes.transfer,
                    width: 16,
                    height: 16,
                    color: AppColors.themeColor,
                  ),
                ),
                const SizedBox(width: AppSpacing.s6),
              ],
              if (methodIcon != null) ...[
                methodIcon!,
                const SizedBox(width: AppSpacing.s6),
              ],
              Flexible(
                child: Text(
                  text,
                  textAlign: TextAlign.end,
                  style: AppTextStyles.body,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
