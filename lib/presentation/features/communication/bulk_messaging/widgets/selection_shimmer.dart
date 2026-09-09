import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/core/theme/app_colors.dart';

class SelectionShimmer extends StatelessWidget {
  final bool isTablet;
  const SelectionShimmer({super.key, required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        itemCount: 12,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: isTablet ? 3 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          mainAxisExtent: 52,
        ),
        itemBuilder: (context, index) {
          return Shimmer.fromColors(
            baseColor: AppColors.messagingShimmerBase,
            highlightColor: AppColors.messagingShimmerHighlight,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }
}
