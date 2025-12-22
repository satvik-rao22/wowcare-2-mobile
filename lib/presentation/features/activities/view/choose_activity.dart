import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/custom_scaffold.dart';
import '../widgets/activity_tile.dart';
import 'edit_create_activity_screens/bathroom_activity.dart';
import 'edit_create_activity_screens/bottle_activity.dart';
import 'edit_create_activity_screens/meal_activity.dart';
import 'edit_create_activity_screens/medication_activity.dart';
import 'edit_create_activity_screens/nap_start_activity.dart';
import 'edit_create_activity_screens/outdoor_activity.dart';
import 'edit_create_activity_screens/photo_activity.dart';

class ChooseActivity extends StatelessWidget {
  const ChooseActivity({super.key, required this.selectedStudents});

  final List<String> selectedStudents ;
  static final Map<String, String> activityIcons = { 'Nap start' : MediaRes.napActivityIcon, 'Nap end' : MediaRes.napActivityIcon, 'Bathroom' : MediaRes.bathroomActivityIcon, 'Bottle' : MediaRes.bottleActivityIcon, 'Meal': MediaRes.mealActivityIcon, 'Incident' : MediaRes.incidentActivityIcon, 'Photo': MediaRes.photoVideoActivityIcon, 'Video': MediaRes.photoVideoActivityIcon,'Medication': MediaRes.medicationActivityIcon, 'Notes' : MediaRes.notesActivityIcon, 'Outdoor' : MediaRes.outdoorActivityIcon, 'Learning' : MediaRes.learningActivityIcon};
  static const Map<String, bool> _allLabels = { // here true means the activity won't be clickable
    'Nap start' : false,
    'Nap end': true,
    'Bathroom' : false,
    'Bottle' : false,
    'Meal' : false,
    'Incident' : true,
    'Photo' : false,
    'Video': false,
    'Medication' : false,
    'Notes' : false,
    'Outdoor' : false,
    'Learning' : false,
  };
  // Map activity name to the destination widget/screen
  static final Map<String, Widget Function(List<String>)> activityRoutes = {
    'Nap start': (students) => NapStartScreen(selectedStudents: students),
    'Nap end': (students) => NapStartScreen(selectedStudents: students),
    'Bathroom': (students) => BathroomActivityScreen(selectedStudents: students),
    'Bottle': (students) => BottleActivityScreen(selectedStudents: students),
    'Meal': (students) => MealActivityScreen(selectedStudents: students),
    'Incident': (students) => NapStartScreen(selectedStudents: students),
    'Photo': (students) => PhotoVideoActivityScreen(selectedStudents: students, isPhoto: true,),
    'Video': (students) => PhotoVideoActivityScreen(selectedStudents: students, isPhoto: false),
    'Medication': (students) => MedicationActivityScreen(selectedStudents: students),
    'Notes': (students) => NapStartScreen(selectedStudents: students),
    'Outdoor': (students) => OutdoorActivityScreen(selectedStudents: students),
    'Learning': (students) => NapStartScreen(selectedStudents: students),
  };


  @override
  Widget build(BuildContext context) {
    //String? selectedActivity;
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
                    Expanded(
                        child: GridView.builder(
                            padding: EdgeInsets.all(10),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: responsive.isTablet ? 3 : 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: responsive.isTablet ? 3.8 : 3
                            ),
                            itemCount: activityIcons.length,
                            itemBuilder: (context, index) {
                              final entry = activityIcons.entries.toList()[index];
                              final iconPath = entry.value;
                              final String activityName = entry.key;
                              final bool unavailableActivity = _allLabels[activityName] ?? false;

                              return ActivityTile(
                                iconPath: iconPath,
                                label: activityName,
                                unavailableActivity: unavailableActivity,
                                onTap: unavailableActivity
                                    ? null
                                    : (){
                                      final destinationBuilder = activityRoutes[activityName];
                                      if(destinationBuilder != null) {
                                        final nextScreen = destinationBuilder(selectedStudents);
                                        Navigator.of(context).push(MaterialPageRoute(builder: (_) => nextScreen));
                                      }
                                    }
                                ,
                              );
                            }
                        )
                    ),


                  ],
                ),
              )
          ),
        ],
      ),
    );
  }
}
