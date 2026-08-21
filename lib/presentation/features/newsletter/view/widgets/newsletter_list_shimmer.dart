import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../../../app/theme/colors.dart';

/// Loading placeholder that mirrors [NewsletterSentListCard] so the list
/// keeps its shape while the first page is fetched.
class NewsletterListShimmer extends StatelessWidget {
  const NewsletterListShimmer({super.key, this.itemCount = 6});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: itemCount,
      itemBuilder: (BuildContext context, int index) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: _NewsletterCardShimmer(),
        );
      },
    );
  }
}

class _NewsletterCardShimmer extends StatelessWidget {
  const _NewsletterCardShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey.shade300,
      highlightColor: AppColors.grey.shade100,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.primaryColor.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              width: 84,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            const SizedBox(width: 12),
            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _bar(widthFactor: 0.7, height: 14),
                  const SizedBox(height: 8),
                  _bar(widthFactor: 0.55, height: 11),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(child: _bar(widthFactor: 0.6, height: 11)),
                      const SizedBox(width: 12),
                      _box(width: 34, height: 11),
                    ],
                  ),
                  const SizedBox(height: 8),
                  _bar(widthFactor: 0.5, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 6),
            _box(width: 16, height: 16),
          ],
        ),
      ),
    );
  }

  Widget _bar({required double widthFactor, required double height}) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: _box(height: height),
    );
  }

  Widget _box({double? width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
