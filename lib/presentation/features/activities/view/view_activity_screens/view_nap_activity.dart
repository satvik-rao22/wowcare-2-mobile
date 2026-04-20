import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/widgets/view_widget.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../../app/theme/colors.dart';
import '../../../staff/widgets/staff_form_layout.dart';
import '../../../../../shared/common/widgets/selected_student_tile.dart';
import '../activity_daily_tab.dart';

class ViewNapActivity extends StatelessWidget {
  final ActivityItem activityData;
  final bool isNapStart;
  const ViewNapActivity({
    super.key,
    required this.activityData,
    this.isNapStart = true,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return StaffFormLayout(
      title: isNapStart ? 'Nap Start' : 'Nap End',
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.only(bottom: 40),
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
                      color: Color(0xFFB1AFE9).withOpacity(0.102),
                      //color: Colors.white.withOpacity(0.85),
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
              child: ViewWidget(
                label: 'Date',
                content: activityData.date,
                twoMaxLines: true,
              ),
            ),
            SizedBox(height: responsive.verticalSpacing),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalSpacing,
              ),
              child: ViewWidget(
                label: isNapStart ? 'Nap Start Time' : 'Nap Started at',
                content: activityData.napStartTime ?? 'N/A',
              ),
            ),
            if (!isNapStart) ...[
              SizedBox(height: responsive.verticalSpacing),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalSpacing,
                ),
                child: ViewWidget(
                  label: 'Nap Ended at',
                  content: activityData.napEndTime ?? 'N/A',
                ),
              ),
            ],
            SizedBox(height: responsive.verticalSpacing),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalSpacing,
              ),
              child: ViewWidget(
                label: 'Logged Time',
                content: activityData.time,
              ),
            ),

            SizedBox(height: responsive.verticalSpacing),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: responsive.horizontalSpacing,
              ),
              child: ViewWidget(
                label: 'Description',
                content: activityData.description ?? 'No description',
              ),
            ),

            if (isNapStart) ...[
              SizedBox(height: responsive.verticalSpacing),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalSpacing,
                ),
                child: Row(
                  children: [
                    if (activityData.remainderOn == true)
                      Icon(Icons.check_circle, color: AppColors.primaryColor)
                    else
                      Icon(
                        Icons.radio_button_unchecked,
                        color: AppColors.primaryColor,
                      ),
                    const SizedBox(width: 8),
                    Text(
                      'Remind to check nap every 15 mins',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff573353),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      bottomBar: const SizedBox.shrink(),
    );
  }
}
