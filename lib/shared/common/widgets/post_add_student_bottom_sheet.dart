import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

class PostAddStudentBottomSheet extends StatelessWidget {
  final String studentName;
  final VoidCallback onLater;
  final VoidCallback onYes;

  const PostAddStudentBottomSheet({
    super.key,
    required this.studentName,
    required this.onLater,
    required this.onYes,
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
          decoration: BoxDecoration(
            color: AppPalette.surfaceSunken,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadius),
              topRight: Radius.circular(borderRadius),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(height: verticalPadding / 2),
              Center(
                child: Container(
                  width: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                  height: isLargeTablet ? 80.0 : (isTablet ? 70.0 : 60.0),
                  decoration: const BoxDecoration(
                    color: AppPalette.brand,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school,
                    color: AppPalette.onBrand,
                    size: 36,
                  ),
                ),
              ),
              SizedBox(height: verticalPadding),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: horizontalPadding / 2,
                ),
                child: Text(
                  'Do you want to add additional details for this student now?',
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
              const SizedBox(height: 8),
              Text(
                'A new student${studentName.isNotEmpty ? ' $studentName ' : ' '}is added successfully',
                style: const TextStyle(
                  fontFamily: AppFonts.body,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: verticalPadding * 1.5),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: buttonHeight,
                      decoration: AppSurfaces.key(
                        KeyVariant.secondary,
                        radius: borderRadius / 2,
                      ),
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
                            onPressed: onLater,
                            style: TextButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  borderRadius / 2 - 1,
                                ),
                              ),
                            ),
                            child: Text(
                              'Do it later',
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
                    child: Container(
                      height: buttonHeight,
                      decoration: AppSurfaces.key(
                        KeyVariant.primary,
                        radius: borderRadius / 2,
                      ),
                      child: TextButton(
                        onPressed: onYes,
                        style: TextButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              borderRadius / 2,
                            ),
                          ),
                        ),
                        child: Text(
                          'Yes',
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
