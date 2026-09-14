import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/primary_circular_loader.dart';
import 'package:wowcare/core/theme/app_colors.dart';

/// Small pill shown at the top of the message list while an older-history
/// page is being fetched. Rendered as an overlay (not a list item) so it
/// never contributes to the scrollable content's `maxScrollExtent` — that
/// would throw off the scroll-position-preserving math run right after the
/// older page lands.
class LoadingOlderIndicator extends StatelessWidget {
  const LoadingOlderIndicator({super.key, required this.visible});

  final bool visible;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 150),
      opacity: visible ? 1 : 0,
      child: IgnorePointer(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.blackColor.withValues(alpha: 0.12),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const PrimaryCircularLoader(size: 16, strokeWidth: 2),
            ),
          ),
        ),
      ),
    );
  }
}
