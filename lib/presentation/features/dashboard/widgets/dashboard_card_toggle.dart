import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// Compact `+ / -` key used by every dashboard card to collapse or expand
/// its body.
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
            SkeuKeyBox(
              variant: KeyVariant.primary,
              radius: 8,
              width: 26,
              height: 26,
            ),
            Container(
              width: 21,
              height: 21,
              decoration: BoxDecoration(
                color: AppColors.whiteColor,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            _glyph(),
          ],
        ),
      ),
    );
  }

  /// The glyph swaps with a quick scale-and-fade, in step with the body.
  Widget _glyph() {
    return AnimatedSwitcher(
      duration: AppMotion.fast,
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeOut,
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Icon(
        minimized ? Icons.add : Icons.remove,
        key: ValueKey<bool>(minimized),
        color: AppColors.themeColor,
        size: 18,
      ),
    );
  }
}
