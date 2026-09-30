import 'package:flutter/material.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';

/// Section label shown above the first row of each category group of
/// notification-preference rows. Takes the already-humanised
/// `NotificationPreferenceGroup.categoryLabel`, never the raw backend enum.
class NotificationPreferenceCategoryHeader extends StatelessWidget {
  const NotificationPreferenceCategoryHeader({super.key, required this.categoryLabel});

  final String categoryLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
      child: Text(
        categoryLabel,
        style: const TextStyle(
          fontFamily: AppFonts.body,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
          color: AppColors.themeColor,
        ),
      ),
    );
  }
}
