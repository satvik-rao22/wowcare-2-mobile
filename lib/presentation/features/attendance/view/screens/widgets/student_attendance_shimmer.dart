import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StudentAttendanceCardShimmer extends StatelessWidget {
  const StudentAttendanceCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final avatarSize = responsive.isTablet ? 52.0 : 50.0;
    final cardPadding = responsive.isTablet
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final spacing = responsive.isTablet ? 16.0 : 9.0;

    return Shimmer.fromColors(
      baseColor: AppColors.grey.shade300,
      highlightColor: AppColors.grey.shade100,
      child: Container(
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderColor, width: 1),
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: responsive.verticalSpacing / 2),
                  Container(
                    height: responsive.isTablet ? 16 : 14,
                    width: responsive.isTablet ? 140 : 120,
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(4),
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
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StudentAbsentCardShimmer extends StatelessWidget {
  const StudentAbsentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final avatarSize = responsive.isTablet ? 52.0 : 50.0;
    final cardPadding = responsive.isTablet
        ? const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
        : const EdgeInsets.symmetric(horizontal: 16, vertical: 12);
    final spacing = responsive.isTablet ? 16.0 : 9.0;

    return Shimmer.fromColors(
      baseColor: AppColors.grey.shade300,
      highlightColor: AppColors.grey.shade100,
      child: Container(
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.cardBorderColor, width: 1),
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
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: responsive.verticalSpacing / 2),
                  Container(
                    height: responsive.isTablet ? 16 : 14,
                    width: responsive.isTablet ? 140 : 120,
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: responsive.verticalSpacing / 2),
                  Container(
                    height: responsive.isTablet ? 16 : 14,
                    width: responsive.isTablet ? 110 : 100,
                    decoration: BoxDecoration(
                      color: AppColors.cardColor,
                      borderRadius: BorderRadius.circular(4),
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
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
