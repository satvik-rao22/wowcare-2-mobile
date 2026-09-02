import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/radius.dart';
import 'package:wowcare/app/theme/spacing.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// Loading placeholder for a summary card, shared by the student and staff
/// attendance summary widgets — was an identical private
/// `_buildSummaryCardShimmer` method in both.
class AttendanceSummaryCardShimmer extends StatelessWidget {
  const AttendanceSummaryCardShimmer({super.key, required this.responsive});

  final ResponsiveHelper responsive;

  @override
  Widget build(BuildContext context) {
    return CustomSectionCard(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.horizontalSpacing,
        vertical: responsive.verticalSpacing / 2,
      ),
      child: Row(
        children: [
          Column(
            children: [
              Container(
                width: 40,
                height: 24,
                decoration: BoxDecoration(
                  color: AppColors.attendanceBorderLightColor,
                  borderRadius: AppRadius.allXs,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.attendanceBorderLightColor,
                  borderRadius: AppRadius.allXs,
                ),
              ),
            ],
          ),
          SizedBox(width: responsive.horizontalSpacing / 2),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: responsive.isTablet ? 24 : 20,
                  decoration: BoxDecoration(
                    color: AppColors.attendanceBorderLightColor,
                    borderRadius: AppRadius.allPill,
                  ),
                ),
                SizedBox(height: responsive.verticalSpacing / 2),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: responsive.isTablet ? 18 : 16,
                        decoration: BoxDecoration(
                          color: AppColors.attendanceBorderLightColor,
                          borderRadius: AppRadius.allXs,
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.horizontalSpacing / 4),
                    Expanded(
                      child: Container(
                        height: responsive.isTablet ? 18 : 16,
                        decoration: BoxDecoration(
                          color: AppColors.attendanceBorderLightColor,
                          borderRadius: AppRadius.allXs,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
