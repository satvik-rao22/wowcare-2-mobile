import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';

/// be `const`, takes a key, and rebuilds independently of its host (§6.4).
class SelectionCheckbox extends StatelessWidget {
  const SelectionCheckbox({required this.isSelected});

  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        border: Border.all(
          color: isSelected
              ? AppColors.themeColor
              : AppColors.reportsMutedColor,
          width: 2,
        ),
        borderRadius: BorderRadius.circular(4),
        color: isSelected ? AppColors.themeColor : AppColors.transparentColor,
      ),
      child: isSelected
          ? const Icon(Icons.check, size: 14, color: AppColors.cardColor)
          : null,
    );
  }
}
