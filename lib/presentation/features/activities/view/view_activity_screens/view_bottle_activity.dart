import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/activities/widgets/view_widget.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../../app/theme/colors.dart';
import '../../../staff/widgets/staff_form_layout.dart';
import '../../../../../shared/common/widgets/selected_student_tile.dart';
import '../activity_daily_tab.dart';

String _stripTrailingListPunctuation(String s) {
  return s.replaceAll(RegExp(r'[\s,;]+$'), '').trim();
}

String _primaryStudentName(ActivityItem a) {
  if (a.studentList.isEmpty) return '';
  return a.studentList.first.trim();
}

String _initialsFromName(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) {
    final w = parts.first;
    return w.length >= 2 ? w.substring(0, 2).toUpperCase() : w.toUpperCase();
  }
  return ('${parts[0][0]}${parts[1][0]}').toUpperCase();
}

class ViewBottleActivity extends StatelessWidget {
  final ActivityItem activityData;
  const ViewBottleActivity({super.key, required this.activityData});

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    final primaryName = _primaryStudentName(activityData);
    final amount =
        (formatBottleAmountForDisplay(activityData.amountConsumed) ?? '').trim();
    final status = (activityData.bottleConsumptionStatus ?? '').trim();
    final statusLine =
        status.isEmpty ? '' : _stripTrailingListPunctuation(status);
    final description = (activityData.description ?? '').trim();

    return StaffFormLayout(
      title: 'Bottle',
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 40),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalSpacing,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tagged Students',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Manrope',
                    ),
                  ),
                  SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFB1AFE9).withOpacity(0.102),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryColor),
                    ),
                    child: Wrap(
                      spacing: 12.0,
                      runSpacing: 12.0,
                      alignment: WrapAlignment.start,
                      children: activityData.studentList.map((name) {
                        return IntrinsicWidth(
                          child: SelectedStudentTile(
                            name: name,
                            isViewActivityScreen: true,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: responsive.verticalSpacing),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalSpacing,
              ),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9F0),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.dividerColor),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: responsive.isTablet ? 100 : 88,
                      height: responsive.isTablet ? 100 : 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.dividerColor,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.asset(
                          MediaRes.bottleActivityIcon,
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFE082),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Bottle',
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff573353),
                              ),
                            ),
                          ),
                          if (primaryName.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor: AppColors.themeColor
                                      .withOpacity(0.25),
                                  child: Text(
                                    _initialsFromName(primaryName),
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xff573353),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    activityData.studentList.join(', '),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xff573353),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (amount.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              amount,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryColor,
                              ),
                            ),
                          ],
                          if (statusLine.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              statusLine,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppColors.primaryColor.withOpacity(0.85),
                              ),
                            ),
                          ],
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              description,
                              style: TextStyle(
                                fontFamily: 'Manrope',
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                height: 1.35,
                                color: AppColors.primaryColor.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: responsive.verticalSpacing),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalSpacing,
              ),
              child: Row(
                children: [
                  Flexible(
                    child: ViewWidget(
                      label: 'Date',
                      content: activityData.date,
                      twoMaxLines: true,
                    ),
                  ),
                  SizedBox(width: responsive.horizontalSpacing),
                  Flexible(
                    child: ViewWidget(
                      label: 'Time',
                      content: activityData.time,
                      twoMaxLines: false,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomBar: const SizedBox.shrink(),
    );
  }
}
