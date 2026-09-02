import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/dimensions.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StaffAttendanceCardShimmer extends StatelessWidget {
  const StaffAttendanceCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final avatarSize = responsive.isTablet ? 52.0 : 50.0;
    final cardPadding = responsive.isTablet
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          )
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          );
    final spacing = responsive.isTablet ? 16.0 : 9.0;

    return Shimmer.fromColors(
      baseColor: AppColors.attendanceShimmerBaseColor,
      highlightColor: AppColors.attendanceShimmerHighlightColor,
      child: Container(
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: AppColors.cardBorderColor, width: AppDimensions.hairline),
        ),
        child: Row(
          children: [
            // Avatar shimmer
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: spacing),
            // Content shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: responsive.isTablet ? 18 : 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: AppRadius.allXs,
                    ),
                  ),
                  SizedBox(height: responsive.verticalSpacing / 2),
                  Container(
                    height: responsive.isTablet ? 16 : 14,
                    width: responsive.isTablet ? 140 : 120,
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: AppRadius.allXs,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing / 2),
            // Duration shimmer
            Flexible(
              child: Container(
                height: responsive.isTablet ? 18 : 16,
                width: responsive.isTablet ? 90 : 80,
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: AppRadius.allXs,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaffAbsentCardShimmer extends StatelessWidget {
  const StaffAbsentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final avatarSize = responsive.isTablet ? 52.0 : 50.0;
    final cardPadding = responsive.isTablet
        ? const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          )
        : const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          );
    final spacing = responsive.isTablet ? 16.0 : 9.0;

    return Shimmer.fromColors(
      baseColor: AppColors.attendanceShimmerBaseColor,
      highlightColor: AppColors.attendanceShimmerHighlightColor,
      child: Container(
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: AppRadius.allMd,
          border: Border.all(color: AppColors.cardBorderColor, width: AppDimensions.hairline),
        ),
        child: Row(
          children: [
            // Avatar shimmer
            Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: spacing),
            // Content shimmer
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: responsive.isTablet ? 18 : 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: AppRadius.allXs,
                    ),
                  ),
                  SizedBox(height: responsive.verticalSpacing / 2),
                  Container(
                    height: responsive.isTablet ? 16 : 14,
                    width: responsive.isTablet ? 140 : 120,
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: AppRadius.allXs,
                    ),
                  ),
                  SizedBox(height: responsive.verticalSpacing / 2),
                  Container(
                    height: responsive.isTablet ? 16 : 14,
                    width: responsive.isTablet ? 110 : 100,
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: AppRadius.allXs,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: spacing / 2),
            // Status shimmer
            Flexible(
              child: Container(
                height: responsive.isTablet ? 28 : 24,
                width: responsive.isTablet ? 70 : 60,
                decoration: BoxDecoration(
                  color: AppColors.cardColor,
                  borderRadius: AppRadius.allMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
