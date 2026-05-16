// used for displaying all content related to strings like date, time, description
import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import '../../../../app/theme/colors.dart';

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
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            fontFamily: 'Manrope',
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Color(0xFFB1AFE9).withOpacity(0.102),
            //color: Colors.white.withOpacity(0.85),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primaryColor),
          ),
          child: Text(
            content,
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              fontFamily: 'Manrope',
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: twoMaxLines ? 2 : 1,
          ),
        ),
      ],
    );
  }
}
