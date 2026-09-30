import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

class ConfirmationBottomSheet extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String confirmText;
  final String cancelText;
  final IconData? icon;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  const ConfirmationBottomSheet({
    super.key,
    required this.title,
    this.subtitle,
    this.confirmText = 'Yes',
    this.cancelText = 'Skip',
    this.icon,
    required this.onConfirm,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    final horizontalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
    final verticalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
    final titleFontSize = isLargeTablet ? 20.0 : (isTablet ? 18.0 : 16.0);
    final buttonHeight = isLargeTablet ? 56.0 : (isTablet ? 48.0 : 40.0);
    final buttonFontSize = isLargeTablet ? 18.0 : (isTablet ? 16.0 : 14.0);
    final borderRadius = isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLargeTablet ? 1200.0 : double.infinity,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: verticalPadding,
            bottom: verticalPadding + bottomSafe,
          ),
          decoration: AppSurfaces.sheet(topRadius: borderRadius),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: verticalPadding / 2),
              if (icon != null)
                Center(
                  child: Container(
                    width: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                    height: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                    decoration: const BoxDecoration(
                      color: AppPalette.brand,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: AppPalette.onBrand, size: 36),
                  ),
                ),
              if (icon != null) SizedBox(height: verticalPadding),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding / 2,
                ),
                child: Text(
                  title,
                  style: TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: titleFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryColor,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    fontFamily: AppFonts.body,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              SizedBox(height: verticalPadding * 1.5),
              Row(
                children: [
                  Expanded(
                    child: SkeuKeyBox(
                      variant: KeyVariant.secondary,
                      radius: borderRadius / 2,
                      height: buttonHeight,
                      child: Padding(
                        padding: const EdgeInsets.all(1),
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.transparentColor,
                            borderRadius: BorderRadius.circular(
                              borderRadius / 2 - 1,
                            ),
                          ),
                          child: TextButton(
                            onPressed: onCancel,
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius / 2 - 1,
                                ),
                              ),
                            ),
                            child: Text(
                              cancelText,
                              style: TextStyle(
                                fontFamily: AppFonts.body,
                                fontSize: buttonFontSize,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryColor,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: horizontalPadding / 2),
                  Expanded(
                    child: SkeuKeyBox(
                      variant: KeyVariant.primary,
                      radius: borderRadius / 2,
                      height: buttonHeight,
                      child: TextButton(
                        onPressed: onConfirm,
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              borderRadius / 2,
                            ),
                          ),
                        ),
                        child: Text(
                          confirmText,
                          style: TextStyle(
                            fontFamily: AppFonts.body,
                            fontSize: buttonFontSize,
                            fontWeight: FontWeight.w700,
                            color: AppPalette.onBrand,
                            height: 1.0,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
