import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';

/// Indicator showing active filters with a badge.
/// Only displayed when filters are active.
class FilterIndicator extends StatelessWidget {
  const FilterIndicator({
    super.key,
    required this.hasActiveFilters,
    required this.filterCount,
    required this.onTap,
  });

  final bool hasActiveFilters;
  final int filterCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (!hasActiveFilters) {
      return IconButton(
        icon: const Icon(Icons.tune),
        onPressed: onTap,
        tooltip: 'Filters',
      );
    }

    return Stack(
      alignment: Alignment.topRight,
      children: [
        IconButton(
          icon: const Icon(Icons.tune),
          onPressed: onTap,
          color: AppColors.primaryColor,
          tooltip: 'Filters (Active)',
        ),
        // Badge with filter count
        Positioned(
          right: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.primaryColor,
              shape: BoxShape.circle,
            ),
            child: Text(
              filterCount.toString(),
              style: AppTextStyles.size14.copyWith(
                color: AppColors.messagingOnAccent,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
