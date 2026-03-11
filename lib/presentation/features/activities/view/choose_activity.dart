import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

import '../../../../app/theme/media_res.dart';
import '../../../../shared/common/widgets/custom_button_layout.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'edit_create_activity_screens/bathroom_activity.dart';
import 'edit_create_activity_screens/bottle_activity.dart';
import 'edit_create_activity_screens/incident_activity.dart';
import 'edit_create_activity_screens/learning_activity.dart';
import 'edit_create_activity_screens/meal_activity.dart';
import 'edit_create_activity_screens/medication_activity.dart';
import 'edit_create_activity_screens/nap_activity.dart';
import 'edit_create_activity_screens/notes_activity.dart';
import 'edit_create_activity_screens/outdoor_activity.dart';
import 'edit_create_activity_screens/photo_activity.dart';

class ChooseActivity extends StatefulWidget {
  const ChooseActivity({super.key, required this.selectedStudents});

  final List<Map<String, dynamic>> selectedStudents ;
  static final Map<String, String> activityIcons = {
    'Nap': MediaRes.napActivityIcon,
    'Bathroom': MediaRes.bathroomActivityIcon,
    'Bottle': MediaRes.bottleActivityIcon,
    'Meal': MediaRes.mealActivityIcon,
    'Incident': MediaRes.incidentActivityIcon,
    'Photo': MediaRes.photoVideoActivityIcon,
    'Video': MediaRes.photoVideoActivityIcon,
    'Medication': MediaRes.medicationActivityIcon,
    'Notes': MediaRes.notesActivityIcon,
    'Outdoor': MediaRes.outdoorActivityIcon,
    'Learning': MediaRes.learningActivityIcon,
  };
  // Map activity name to the destination widget/screen
  static final Map<String, Widget Function(List<Map<String, dynamic>>)> activityRoutes = {
    'Nap': (students) => NapActivityScreen(selectedStudents: students),
    'Bathroom': (students) => BathroomActivityScreen(selectedStudents: students),
    'Bottle': (students) => BottleActivityScreen(selectedStudents: students),
    'Meal': (students) => MealActivityScreen(selectedStudents: students),
    'Incident': (students) => IncidentActivityScreen(selectedStudents: students),
    'Photo': (students) => PhotoVideoActivityScreen(selectedStudents: students, isPhoto: true,),
    'Video': (students) => PhotoVideoActivityScreen(selectedStudents: students, isPhoto: false),
    'Medication': (students) => MedicationActivityScreen(selectedStudents: students),
    'Notes': (students) => NotesActivityScreen(selectedStudents: students),
    'Outdoor': (students) => OutdoorActivityScreen(selectedStudents: students),
    'Learning': (students) => LearningActivityScreen(selectedStudents: students),
  };

  @override
  State<ChooseActivity> createState() => _ChooseActivityState();
}

class _ChooseActivityState extends State<ChooseActivity> {
  bool get _isMultipleStudentsSelected => widget.selectedStudents.length > 1;
  String? _selectedActivity;

  bool _isActivityDisabled(String activityName) {
    if (activityName == 'Incident' && _isMultipleStudentsSelected) {
      return true;
    }
    return false;
  }

  String _getDisabledActivityTooltip(String activityName) {
    if (activityName == 'Incident' && _isMultipleStudentsSelected) {
      return 'Incident can only be recorded for a single student.';
    }
    return 'This activity is currently disabled';
  }

  void _showDisabledActivityTooltip(BuildContext tileContext, String activityName) {
    final RenderBox renderBox = tileContext.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: position.dy - 60,
        left: position.dx,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _getDisabledActivityTooltip(activityName),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _showWarningMessage(String message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).removeCurrentSnackBar();
      final snackBar = SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.orange.shade50,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: Colors.orange.shade100),
        ),
      );
      ScaffoldMessenger.of(context).showSnackBar(snackBar);
    });
  }

  @override
  Widget build(BuildContext context) {
    final safeAreaBottom = MediaQuery.of(context).padding.bottom;

    return StaffFormLayout(
      title: 'Choose Activity',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: GridView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: false,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                mainAxisExtent: 52,
              ),
              itemCount: ChooseActivity.activityIcons.length,
              itemBuilder: (context, index) {
                final entry = ChooseActivity.activityIcons.entries.toList()[index];
                final iconPath = entry.value;
                final String activityName = entry.key;
                final bool isDisabled = _isActivityDisabled(activityName);
                final bool isSelected = _selectedActivity == activityName;

                return Builder(
                  builder: (tileContext) {
                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: isDisabled
                          ? () => _showDisabledActivityTooltip(tileContext, activityName)
                          : () {
                              setState(() {
                                _selectedActivity = activityName;
                              });
                            },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isDisabled
                                ? Colors.grey.withOpacity(0.3)
                                : AppColors.primaryColor.withOpacity(0.1),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(8),
                          color: isDisabled
                              ? Colors.grey.withOpacity(0.1)
                              : isSelected
                                  ? const Color.fromARGB(255, 249, 245, 250)
                                  : Colors.transparent,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 32,
                              height: 32,
                              child: Image.asset(
                                iconPath,
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                activityName.toUpperCase(),
                                softWrap: true,
                                overflow: TextOverflow.ellipsis,
                                maxLines: activityName.contains(' ') ? 2 : 1,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: isDisabled
                                      ? Colors.grey
                                      : AppColors.primaryColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      bottomBar: Padding(
        padding: EdgeInsets.only(bottom: safeAreaBottom),
        child: CustomButtonLayout(
          confirmButtonLabel: 'Next',
          cancelButtonLabel: 'Cancel',
          onPressedCancel: () => Navigator.of(context).pop(),
          onPressedConfirm: () {
            if (_selectedActivity == null) {
              _showWarningMessage('Select an activity.');
              return;
            }

            final destinationBuilder =
                ChooseActivity.activityRoutes[_selectedActivity!];
            if (destinationBuilder != null) {
              final nextScreen = destinationBuilder(widget.selectedStudents);
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => nextScreen),
              );
            }
          },
        ),
      ),
    );
  }
}
