import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_stat_bar_card.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'attendance_summary_card_shimmer.dart';

class StaffAttendanceSummary extends StatelessWidget {
  final int totalStaff;
  final int active;
  final int upcoming;
  final int expected;
  final int present;
  final int absent;
  final int signedOut;
  final int notMarked;
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
    this.signedOut = 0,
    this.notMarked = 0,
    this.isLoading = false,
    this.onLegendTap,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);

    if (isLoading) {
      return Column(
        children: [
          AttendanceSummaryCardShimmer(responsive: responsive),
          SizedBox(height: responsive.verticalSpacing / 2),
          AttendanceSummaryCardShimmer(responsive: responsive),
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
          normalizeBarByItemSum: true,
          items: [
            ProgressItemHelper(
              label: 'Signed-In ($present)',
              value: present.toDouble(),
              color: AppColors.lightGreenProgressBar,
              filterValue: 'Signed-In',
            ),
            ProgressItemHelper(
              label: 'Absent ($absent)',
              value: absent.toDouble(),
              color: AppColors.redProgressBar,
              filterValue: 'Absent',
            ),
            ProgressItemHelper(
              label: 'Signed Out ($signedOut)',
              value: signedOut.toDouble(),
              color: AppColors.lightBlueProgressBar,
              filterValue: 'Signed Out',
            ),
            ProgressItemHelper(
              label: 'Not Marked ($notMarked)',
              value: notMarked.toDouble(),
              color: AppColors.mustardProgressBar,
              filterValue: 'Not Marked',
            ),
          ],
          onLegendTap: onLegendTap != null
              ? (label, filterValue) {
                  final status = label.split(' ').first;
                  if (status == 'Signed-In' ||
                      status == 'Absent' ||
                      status == 'Signed' ||
                      status == 'Not') {
                    if (status == 'Signed') {
                      onLegendTap!('Signed Out');
                    } else if (status == 'Not') {
                      onLegendTap!('Not Marked');
                    } else {
                      onLegendTap!(status);
                    }
                  }
                }
              : null,
        ),
      ],
    );
  }
}
