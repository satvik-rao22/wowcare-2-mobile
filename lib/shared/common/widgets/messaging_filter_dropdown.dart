import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';
import 'custom_dropdown.dart';

class MessagingFilterDropdown extends StatelessWidget {
  final String hintText;
  final List<String> items;
  final String? selectedItem;
  final ValueChanged<String?> onSelect;
  final bool isRequired;
  final double? height;

  const MessagingFilterDropdown({
    super.key,
    required this.hintText,
    required this.items,
    this.selectedItem,
    required this.onSelect,
    this.isRequired = false,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return CustomDropdown(
      label: null,
      hintText: hintText,
      items: items,
      height: height,
      selectedItem: selectedItem,
      onSelect: onSelect,
      showAsterisk: isRequired,
      labelStyle: TextStyle(
        fontSize: responsive.labelFontSize,
        fontFamily: AppFonts.body,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryColor,
      ),
      labelBottomSpacing: responsive.isTablet ? 8.0 : 6.0,
      fieldHeight: 40,
      selectedTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: responsive.inputFontSize,
        fontWeight: selectedItem != null ? FontWeight.w600 : FontWeight.w500,
        color: selectedItem != null
            ? AppColors.primaryColor
            : MaterialHues.grey600,
        height: 19 / 14,
      ),
      popupItemTextStyle: TextStyle(
        fontFamily: AppFonts.body,
        fontSize: responsive.inputFontSize,
        fontWeight: FontWeight.w400,
        color: AppColors.primaryColor,
      ),
    );
  }
}
