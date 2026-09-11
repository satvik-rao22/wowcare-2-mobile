import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/reports/widgets/selection_checkbox.dart';
import 'package:wowcare/core/constants/app_sizes.dart';

/// One tappable row of a multi-select popup: a check indicator, a gap and a
/// label.
///
/// The "Select All" row and every item row were the same
/// `InkWell > Container > Row[checkbox, gap, Expanded(Text)]` structure with
/// different copy and callback (§6.8) — this is that structure, once.
class SelectionRow extends StatelessWidget {
  const SelectionRow({
    super.key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isEmphasised = false,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  /// The "Select All" row uses the plain inherited label style; item rows use
  /// the darker body colour.
  final bool isEmphasised;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.sm,
          vertical: AppSizes.sm,
        ),
        child: Row(
          children: [
            SelectionCheckbox(isSelected: isSelected),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Text(
                label,
                style: isEmphasised
                    ? AppTextStyles.reportsFieldLabel(fontSize: 14).copyWith(
                        color: AppColors.blackColor.withValues(alpha: 0.87),
                      )
                    : AppTextStyles.reportsSelectionRowLabel,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
