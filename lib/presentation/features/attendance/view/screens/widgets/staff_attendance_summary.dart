import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:wowcare/shared/common/widgets/custom_section_card.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class StaffAttendanceSummary extends StatelessWidget {
  final int totalStaff;
  final int active;
  final int upcoming;
  final int expected;
  final int present;
  final int absent;
  final bool isLoading;
  final Function(String)? onLegendTap;

  const StaffAttendanceSummary({
    super.key,
    required this.totalStaff,
    required this.active,
    required this.upcoming,
    required this.expected,
    required this.present,
    required this.absent,
    this.isLoading = false,
    this.onLegendTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    
    if (isLoading) {
      return Column(
        children: [
          _buildSummaryCardShimmer(context, responsive),
          SizedBox(height: responsive.verticalSpacing / 2),
          _buildSummaryCardShimmer(context, responsive),
        ],
      );
    }

    return Column(
      children: [
        CustomStatBarCard(
          title: 'Total\nStaff',
          number: totalStaff.toString(),
          items: [
            ProgressItemHelper(
              label: 'Active ($active)',
              value: active.toDouble(),
              color: AppColors.lightBlueProgressBar,
            ),
            ProgressItemHelper(
              label: 'Upcoming ($upcoming)',
              value: upcoming.toDouble(),
              color: AppColors.mustardProgressBar,
            ),
          ],
          onLegendTap: onLegendTap != null
              ? (label, filterValue) {
                  final status = label.split(' ').first;
                  if (status == 'Active' || status == 'Upcoming') {
                    onLegendTap!(status);
                  }
                }
              : null,
        ),
        SizedBox(height: responsive.verticalSpacing / 2),
        CustomStatBarCard(
          title: 'Expected\nStaff',
          number: expected.toString(),
          items: [
            ProgressItemHelper(
              label: 'Present ($present)',
              value: present.toDouble(),
              color: AppColors.lightGreenProgressBar,
              filterValue: 'Present',
            ),
            ProgressItemHelper(
              label: 'Absent ($absent)',
              value: absent.toDouble(),
              color: AppColors.redProgressBar,
              filterValue: 'Absent',
            ),
          ],
          onLegendTap: onLegendTap != null
              ? (label, filterValue) {
                  final status = label.split(' ').first;
                  if (status == 'Present' || status == 'Absent') {
                    onLegendTap!(status);
                  }
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildSummaryCardShimmer(BuildContext context, ResponsiveHelper responsive) {
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
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(4),
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
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
                SizedBox(height: responsive.verticalSpacing / 2),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: responsive.isTablet ? 18 : 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    SizedBox(width: responsive.horizontalSpacing / 4),
                    Expanded(
                      child: Container(
                        height: responsive.isTablet ? 18 : 16,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
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
