import 'package:flutter/material.dart';
import 'package:schoolerp/core/helpers/progress_item_helper.dart';
import '../../../app/theme/colors.dart';

class CustomStatBarCard extends StatelessWidget {
  const CustomStatBarCard({
    required this.title,
    required this.number,
    required this.items,
    this.onLegendTap,
    this.fullWidthBar = false,
    super.key,
  });

  final String title;
  final String number;
  final List<ProgressItemHelper> items;
  final void Function(String label)? onLegendTap;
  final bool fullWidthBar;

  @override
  Widget build(BuildContext context) {
    int total = int.tryParse(number) ?? 0;
    double sumValues = items.fold(0, (sum, item) => sum + item.value);
    bool hasValidTotal = total > 0;

    if (fullWidthBar) {
      // Admin billing style: label and value above, bar full width
      final percentSum = items.fold<double>(0, (sum, item) => sum + item.value);
      final percentList = items.map((item) => item.value).toList();
      final percentTotal = percentList.fold(0.0, (a, b) => a + b);
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorderColor),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.cardColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppColors.primaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 22,
                    color: AppColors.themeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: SizedBox(
                height: 20,
                width: double.infinity,
                child: Row(
                  children: percentTotal == 0
                      ? [Expanded(child: Container(color: Colors.grey[300]))]
                      : [
                          ...items.map(
                            (item) => Expanded(
                              flex: ((item.value * 1000) ~/ percentTotal),
                              child: Container(color: item.color),
                            ),
                          ),
                          if (percentTotal < 100)
                            Expanded(
                              flex: ((100 - percentTotal) * 1000 ~/ 100),
                              child: Container(color: Colors.grey[300]),
                            ),
                        ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 4,
              children: items
                  .map(
                    (item) => Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 10,
                          width: 10,
                          decoration: BoxDecoration(
                            color: item.color,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        onLegendTap != null
                            ? GestureDetector(
                                onTap: () => onLegendTap!(item.label),
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    color: AppColors.primaryColor.withOpacity(
                                      0.8,
                                    ),
                                    fontSize: 13,
                                  ),
                                ),
                              )
                            : Text(
                                item.label,
                                style: TextStyle(
                                  color: AppColors.primaryColor.withOpacity(
                                    0.8,
                                  ),
                                  fontSize: 13,
                                ),
                              ),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      );
    } else {
      // Original style
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorderColor),
          borderRadius: BorderRadius.circular(12),
          color: AppColors.cardColor,
        ),
        child: Row(
          children: [
            Column(
              children: [
                Text(
                  number,
                  style: const TextStyle(
                    fontSize: 24,
                    color: AppColors.themeColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.primaryColor.withOpacity(0.8),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: SizedBox(
                      height: 20,
                      child: Row(
                        children: !hasValidTotal
                            ? [
                                Expanded(
                                  child: Container(color: Colors.grey[300]),
                                ),
                              ]
                            : [
                                ...items.map(
                                  (item) => Expanded(
                                    flex: hasValidTotal
                                        ? (item.value * 100 ~/ total)
                                        : 1,
                                    child: Container(color: item.color),
                                  ),
                                ),
                                if (sumValues < total)
                                  Expanded(
                                    flex: hasValidTotal
                                        ? ((total - sumValues) * 100 ~/ total)
                                        : 1,
                                    child: Container(color: Colors.grey[300]),
                                  ),
                              ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 16,
                    runSpacing: 4,
                    children: items
                        .map(
                          (item) => Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: 10,
                                width: 10,
                                decoration: BoxDecoration(
                                  color: item.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              onLegendTap != null
                                  ? GestureDetector(
                                      onTap: () => onLegendTap!(item.label),
                                      child: Text(
                                        item.label,
                                        style: TextStyle(
                                          color: AppColors.primaryColor
                                              .withOpacity(0.8),
                                          fontSize: 13,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      item.label,
                                      style: TextStyle(
                                        color: AppColors.primaryColor
                                            .withOpacity(0.8),
                                        fontSize: 13,
                                      ),
                                    ),
                            ],
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
