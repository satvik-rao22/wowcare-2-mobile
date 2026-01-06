import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/activities/widgets/view_activity_media.dart';
import 'package:wowcare/presentation/features/activities/widgets/view_widget.dart';
import 'package:wowcare/shared/common/widgets/custom_app_bar.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../../app/theme/colors.dart';
import '../../../../../app/theme/media_res.dart';
import '../../widgets/selected_student_tile.dart';
import '../activity_daily_tab.dart';


class ViewIncidentActivity extends StatelessWidget {
  final ActivityItem activityData;
  const ViewIncidentActivity({super.key, required this.activityData, });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(hasBackButton: true,),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: AppColors.buildScaffoldGradient(),
              ),
              child: Image.asset(
                MediaRes.wowcareMobileBg,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
              ),
            ),
          ),
          Positioned.fill(
            child: SafeArea(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: 40),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.horizontalSpacing,
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Incident Activity Report',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: responsive.titleFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xff573353),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: responsive.isTablet ? 16.0 : 10.0),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: responsive.horizontalSpacing,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tagged Student',
                            style: TextStyle(
                              color: AppColors.primaryColor,
                              fontSize:  13,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Manrope',
                            ),
                          ),
                          SizedBox(height: responsive.isTablet ? 8.0 : 6.0 ),
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
                                return IntrinsicWidth( // Makes each tile only as wide as needed
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
                    SizedBox(height: responsive.verticalSpacing,),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                      child: Row(
                        children: [
                          Flexible(child: ViewWidget(label: 'Date', content: activityData.date, twoMaxLines: true,)),
                          SizedBox(width: responsive.horizontalSpacing,),
                          Flexible(child: ViewWidget(label: 'Time', content: activityData.time, twoMaxLines: false,)),
                        ],
                      ),
                    ),
                    SizedBox(height: responsive.verticalSpacing,),
                    Padding(padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                        child: ViewWidget(label: 'What happened?', content: activityData.whatHappened ?? 'N/A')
                    ),
                    SizedBox(height: responsive.verticalSpacing,),
                    Padding(padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                        child: ViewWidget(label: 'First Aid Administered', content: activityData.firstAidAdministered == true ? 'True': 'False')
                    ),
                    SizedBox(height: responsive.verticalSpacing,),
                    Padding(padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                        child: ViewWidget(label: 'Staff Present', content: activityData.staffPresent ?? 'N/A')
                    ),
                    SizedBox(height: responsive.verticalSpacing,),
                    if(activityData.photoUrl != null)
                      Padding(padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                          child: ActivityMediaViewer(activity: activityData, label: 'Attached Media',)
                      ),
                    SizedBox(height: responsive.verticalSpacing,),
                    Padding(padding: EdgeInsets.symmetric(horizontal: responsive.horizontalSpacing),
                        child: ViewWidget(label: 'Additional Notes', content: activityData.additionalNotes ?? 'N/A')
                    ),


                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}
