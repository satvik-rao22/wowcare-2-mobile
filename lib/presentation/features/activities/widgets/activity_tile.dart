import 'package:flutter/material.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.iconPath,
    required this.label,
    this.onTap,
    this.unavailableActivity = false,
  });

  final String iconPath;
  final String label;
  final bool unavailableActivity;
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
            color: AppColors.cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primaryColor.withValues(alpha: 0.1),
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
                  style: AppTextStyles.activityBodyValue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
