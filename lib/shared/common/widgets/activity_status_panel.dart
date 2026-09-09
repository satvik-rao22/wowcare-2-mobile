import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';

class ActivityStatusPanel extends StatelessWidget {
  const ActivityStatusPanel({
    super.key,
    this.isSignedIN = false,
    this.napStartStatus = false,
    this.napEndStatus = false,
    this.bathroomStatus = false,
    required this.onGoingActivities,

  });

  final bool napStartStatus;
  final bool napEndStatus;
  final bool bathroomStatus;
  final bool isSignedIN;
  final List<String> onGoingActivities;
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
    final List<String> allItems = _allLabels;
    return Material(
      borderRadius: BorderRadius.circular(10),
      elevation: 3,
      child: Container(
        height: 200,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.themeColor),
          color: AppColors.cardColor,
          borderRadius: BorderRadius.circular(10)
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: allItems.asMap().entries.map((entry) {
              final index = entry.key;
              final label = entry.value;
              final iconPath = activityIcons[label] ?? MediaRes.notesActivityIcon;
              final bool isActive = isSignedIN && !onGoingActivities.contains(label);

              return Column(
                children: [
                  _ActivityStatusIcon(
                      iconPath: iconPath,
                      label: label,
                      onGoingActivity: isActive ,
                  ),
                  if (index < allItems.length -1)
                    const SizedBox(height: 10,)
                ],
              );
            }).toList(),
            // children: [
            //   _ActivityStatusIcon(
            //     iconPath: MediaRes.napActivityIcon,
            //     label: 'Nap start',
            //     onGoingActivity: napStartStatus,
            //
            //   ),
            //   const SizedBox(height: 20,),
            //   _ActivityStatusIcon(
            //     iconPath: MediaRes.napActivityIcon,
            //     label: 'Nap end',
            //     onGoingActivity: napEndStatus,
            //   ),
            //   const SizedBox(height: 20,),
            //   _ActivityStatusIcon(
            //     iconPath: MediaRes.bathroomActivityIcon,
            //     label: 'Bathroom',
            //     onGoingActivity: bathroomStatus,
            //
            //   ),
            // ],
          ),
        ),
        

      ),
    );
  }
}

// class ActivityStatusItem {
//   final String iconPath;
//   final String label;
//   final bool isActive;
//   ActivityStatusItem({
//     required this.label,
//     required this.iconPath,
//     required this.isActive
// });
// }

class _ActivityStatusIcon extends StatelessWidget {
  const _ActivityStatusIcon({
    required this.iconPath,
    required this.label,
    this.onGoingActivity = false
  });

  final String iconPath;
  final String label;
  final bool onGoingActivity;


  @override
  Widget build(BuildContext context) {
    final double opacity = onGoingActivity ? 1.0 : 0.4;
    return Opacity(
      opacity: opacity,
      child: Column(
        children: [
          Image.asset(
            iconPath,
            height: 30,
            width: 30,

          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
