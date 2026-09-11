import 'package:flutter/material.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_fonts.dart';
import 'package:wowcare/core/utils/core_utils.dart';

class NonEditableInfoWidget extends StatelessWidget {
  const NonEditableInfoWidget({
    super.key,
    required this.label,
    this.isEditable = true,
    this.value,
    this.isRequired = false,
  });
  final String label;
  final bool isEditable;
  final String? value;
  final bool isRequired;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: AppColors.primaryColor,
              fontSize: responsive.labelFontSize,
              fontFamily: Fonts.manrope,
              fontWeight: FontWeight.w400,
            ),
            children: [
              TextSpan(text: label),
              if (isRequired)
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.userProfileErrorColor),
                ),
            ],
          ),
        ),
        SizedBox(height: responsive.isTablet ? 8.0 : 6.0),
        InkWell(
          onTap: !isEditable
              ? () {
                  CoreUtils.showTopSnackBar(
                    context: context,
                    message: 'Can not be edited.',
                    isError: true,
                  );
                }
              : null,
          child: Opacity(
            opacity: isEditable ? 1.0 : 0.6,
            child: Container(
              constraints: BoxConstraints(
                minHeight: responsive.isTablet ? 64.0 : 56.0,
              ),
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.userProfileSoftPurpleColor.withValues(alpha: 0.102),
                //color: AppColors.userProfileLightBackgroundColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: responsive.isTablet ? 16.0 : 12.0,
                  vertical: responsive.isTablet ? 16.0 : 12.0,
                ),
                child: Text(
                  value!,
                  style: TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: responsive.inputFontSize,
                    fontWeight: FontWeight.w600,
                    color: AppColors.userProfileTextColor,
                    height: 19 / 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.left,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
