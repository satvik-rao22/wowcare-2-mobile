import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:wowcare/core/theme/app_colors.dart';

/// Filter funnel icon button that overlays a red dot on [iconAsset] whenever
/// [isActive] is true, so the applied-filter state stays visible on the
/// button itself after the filter sheet closes (not just on the chips below
/// it, which don't cover every filter field).
class FilterIconButton extends StatelessWidget {
  const FilterIconButton({
    required this.iconAsset,
    required this.isActive,
    required this.onPressed,
    super.key,
    this.iconHeight = 22,
    this.tooltip,
  });

  final String iconAsset;
  final bool isActive;
  final VoidCallback onPressed;
  final double iconHeight;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          SvgPicture.asset(iconAsset, height: iconHeight),
          if (isActive)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                width: 9,
                height: 9,
                decoration: BoxDecoration(
                  color: AppColors.errorColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
