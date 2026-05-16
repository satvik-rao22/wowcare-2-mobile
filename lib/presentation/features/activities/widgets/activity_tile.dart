import 'package:flutter/material.dart';

import '../../../../app/theme/colors.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.iconPath,
    required this.label,
    //required this.selectedStudents,
    this.onTap,
    this.unavailableActivity = false,
  });

  final String iconPath;
  final String label;
  final bool unavailableActivity;
  //final List<String> selectedStudents;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final double opacity = !unavailableActivity ? 1.0 : 0.4;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Opacity(
        opacity: opacity,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xff573353).withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(iconPath, height: 45, width: 45),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
