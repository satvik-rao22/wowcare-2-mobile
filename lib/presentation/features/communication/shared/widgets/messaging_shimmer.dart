import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/theme/colors.dart';

class MessagingShimmer extends StatelessWidget {
  const MessagingShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return Shimmer.fromColors(
            baseColor: AppColors.messagingShimmerBase,
            highlightColor: AppColors.messagingShimmerHighlight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.messagingBorderSubtle, width: 1),
                ),
              ),
              child: Row(
                children: [
                  // Avatar Shimmer
                  Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(
                      color: AppColors.cardColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Content Shimmer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          color: AppColors.cardColor,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          height: 12,
                          color: AppColors.cardColor,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Trailing Shimmer (Time)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 60,
                        height: 10,
                        color: AppColors.cardColor,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: const BoxDecoration(
                          color: AppColors.cardColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
        childCount: 8,
      ),
    );
  }
}
