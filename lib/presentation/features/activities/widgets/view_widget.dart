// used for displaying all content related to strings like date, time, description
import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';

class ViewWidget extends StatelessWidget {
  const ViewWidget({
    super.key,
    required this.label,
    required this.content,
    this.twoMaxLines = true,
  });
  final String label;
  final String content;
  final bool twoMaxLines;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.activityFieldLabel,
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.activitySoftPurpleFieldColor.withValues(alpha: 0.102),
            //color: AppColors.cardColor.withValues(alpha:0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryColor),
          ),
          child: Text(
            content,
            style: AppTextStyles.activityRowValueText,
            overflow: TextOverflow.ellipsis,
            maxLines: twoMaxLines ? 2 : 1,
          ),
        ),
      ],
    );
  }
}
