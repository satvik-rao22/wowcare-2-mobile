import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StaffAttendanceCardShimmer extends StatelessWidget {
  const StaffAttendanceCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final avatarSize = responsive.isTablet ? 52.0 : 44.0;
    final cardPadding = responsive.isTablet 
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    final spacing = responsive.isTablet ? 16.0 : 14.0;

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(responsive.isTablet ? 18 : 16),
          border: Border.all(color: AppColors.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                  color: Colors.white,
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

class StaffAbsentCardShimmer extends StatelessWidget {
  const StaffAbsentCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final avatarSize = responsive.isTablet ? 52.0 : 44.0;
    final cardPadding = responsive.isTablet 
        ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
        : const EdgeInsets.symmetric(horizontal: 12, vertical: 10);
    final spacing = responsive.isTablet ? 16.0 : 14.0;

    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: EdgeInsets.only(bottom: responsive.verticalSpacing / 2),
        padding: cardPadding,
        decoration: BoxDecoration(
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(responsive.isTablet ? 18 : 16),
          border: Border.all(color: AppColors.cardBorderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
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
                  color: Colors.white,
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
