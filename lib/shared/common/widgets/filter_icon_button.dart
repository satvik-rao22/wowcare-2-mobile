import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_media_res.dart';

/// The filter funnel: the one way the app draws it.
///
/// Navy ink on every screen, whether or not a filter is applied. An applied
/// filter is shown by a dot or a count beside the funnel (each screen keeps
/// its own), never by recolouring it; a pink funnel used to mean "tappable"
/// on some screens and nothing on others. Every filter button in the app
/// draws this widget, so changing it here changes all of them.
class FilterGlyph extends StatelessWidget {
  const FilterGlyph({this.size = 22, super.key});

  final double size;

  @override
  Widget build(BuildContext context) =>
      AppIcon(MediaRes.filterIcon, height: size, tone: IconTone.standard);
}

/// Filter funnel icon button that overlays a red dot on the [FilterGlyph]
/// whenever [isActive] is true, so the applied-filter state stays visible on
/// the button itself after the filter sheet closes (not just on the chips
/// below it, which don't cover every filter field).
class FilterIconButton extends StatelessWidget {
  const FilterIconButton({
    required this.isActive,
    required this.onPressed,
    super.key,
    this.iconHeight = 22,
    this.tooltip,
  });

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
          FilterGlyph(size: iconHeight),
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
                  border: Border.all(color: AppPalette.textOnDark, width: 1.2),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
