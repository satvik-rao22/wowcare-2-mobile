import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';

class ChooseActivity extends StatelessWidget {
  const ChooseActivity({super.key});

  static const Map<String, String> activityIcons = { 'Nap start' : MediaRes.napActivityIcon, 'Nap end' : MediaRes.napActivityIcon, 'Bathroom' : MediaRes.bathroomActivityIcon, 'Bottle' : MediaRes.bottleActivityIcon, 'Meal': MediaRes.mealActivityIcon, 'Incident' : MediaRes.incidentActivityIcon, 'Photo': MediaRes.photoVideoActivityIcon, 'Medication': MediaRes.medicationActivityIcon, 'Notes' : MediaRes.notesActivityIcon, 'Outdoor' : MediaRes.outdoorActivityIcon, 'Learning' : MediaRes.learningActivityIcon};
  static const List<String> _allLabels = [
    'Nap start',
    'Nap end',
    'Bathroom',
    'Bottle',
    'Meal',
    'Incident',
    'Photo',
    'Medication',
    'Notes',
    'Outdoor',
    'Learning',
  ];


  @override
  Widget build(BuildContext context) {
    String? selectedActivity;
    final responsive = ResponsiveHelper(context);
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: true,
      body: Column(
        children: [
          const SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalSpacing,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Choose Activity',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: responsive.titleFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xff573353),
                ),
              ),
            ),
          ),
          SizedBox(height: responsive.isTablet ? 32.0 : 20.0),
          Expanded(
              child: Container(
                width: responsive.containerWidth,
                margin: EdgeInsets.symmetric(
                  horizontal: responsive.horizontalSpacing
                ),
                padding: EdgeInsets.all(responsive.isTablet ? 32.0 : 16.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(
                    Radius.circular(responsive.isTablet ? 30.0 : 20.0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10,),

                  ],
                ),
              )
          ),
        ],
      ),
    );
  }
}
