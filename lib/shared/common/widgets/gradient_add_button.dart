import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

class GradientAddButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double? size;
  final double? iconSize;
  final double? borderRadius;
  final double? wantedButtonSize;
  final bool isTablet;
  final bool isLargeTablet;
  final bool isRectangle;

  /// Renders the button grey instead of gradient. [onTap] still fires, so the
  /// caller can explain why it's unavailable (e.g. a tooltip).
  final bool isDisabled;

  const GradientAddButton({
    Key? key,
    this.onTap = null,
    this.size,
    this.iconSize,
    this.borderRadius,
    this.isTablet = false,
    this.isRectangle = true,
    this.isLargeTablet = false,
    this.wantedButtonSize,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Calculate responsive dimensions
    final buttonSize =
        size ??
        (isLargeTablet
            ? 72.0
            : isTablet
            ? 56.0
            : 40.0);
    final buttonIconSize =
        iconSize ??
        (isLargeTablet
            ? 32.0
            : isTablet
            ? 24.0
            : 20.0);
    final buttonBorderRadius =
        borderRadius ??
        (isLargeTablet
            ? 16.0
            : isTablet
            ? 12.0
            : 8.0);

    return onTap == null
        ? Container(
            width: wantedButtonSize ?? buttonSize,
            height: wantedButtonSize ?? buttonSize,
            decoration: BoxDecoration(
              shape: isRectangle ? BoxShape.rectangle : BoxShape.circle,
              gradient:
                  AppColors.buildPrimaryGradient(), // Use your app's gradient
              borderRadius: isRectangle
                  ? BorderRadius.circular(buttonBorderRadius)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: AppColors.blackColor.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(Icons.add, color: AppColors.whiteColor, size: buttonIconSize),
          )
        : GestureDetector(
            onTap: onTap,
            child: Container(
              width: wantedButtonSize ?? buttonSize,
              height: wantedButtonSize ?? buttonSize,
              decoration: BoxDecoration(
                shape: isRectangle ? BoxShape.rectangle : BoxShape.circle,
                color: isDisabled ? MaterialHues.grey300 : null,
                gradient: isDisabled
                    ? null
                    : AppColors.buildPrimaryGradient(), // Use your app's gradient
                borderRadius: isRectangle
                    ? BorderRadius.circular(buttonBorderRadius)
                    : null,
                boxShadow: isDisabled
                    ? null
                    : [
                        BoxShadow(
                          color: AppColors.blackColor.withValues(alpha: 0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Icon(
                Icons.add,
                color: isDisabled ? MaterialHues.grey600 : AppColors.whiteColor,
                size: buttonIconSize,
              ),
            ),
          );
  }
}
