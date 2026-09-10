import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// Compact gradient-bordered `+ / -` button used by dashboard cards to
/// collapse or expand their body.
///
/// Reusable across every dashboard card so the collapse affordance stays
/// visually consistent.
class DashboardCardToggle extends StatelessWidget {
  const DashboardCardToggle({
    super.key,
    required this.minimized,
    required this.onTap,
  });

  /// Whether the owning card is currently collapsed.
  final bool minimized;

  /// Called when the user taps the toggle.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 26,
        height: 26,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Gradient border.
            SkeuKeyBox(
              variant: KeyVariant.primary,
              radius: 8,
              width: 26,
              height: 26,
            ),
            // White inner background.
            Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            // Icon.
            Icon(
              minimized ? Icons.add : Icons.remove,
              color: AppColors.themeColor,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
