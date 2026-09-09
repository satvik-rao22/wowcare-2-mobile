import 'package:flutter/material.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';

/// Section label shown above the first row of each `categoryName` group of
/// notification-preference rows.
class NotificationPreferenceCategoryHeader extends StatelessWidget {
  const NotificationPreferenceCategoryHeader({super.key, required this.categoryName});

  final String categoryName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 6),
      child: Text(
        categoryName,
        style: const TextStyle(
          fontFamily: Fonts.manrope,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
          color: AppColors.themeColor,
        ),
      ),
    );
  }
}
