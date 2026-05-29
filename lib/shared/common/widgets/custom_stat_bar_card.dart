import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class ProgressItemHelper {
  const ProgressItemHelper({
    required this.label,
    required this.value,
    required this.color,
    this.filterValue
  });

  final String label;
  final double value;
  final Color color;
  final String? filterValue;
}

class CustomStatBarCard extends StatelessWidget {
  const CustomStatBarCard({
    required this.title,
    required this.number,
    required this.items,
    this.progressItems,
    this.onLegendTap,
    this.onHeaderTap,
    this.fullWidthBar = false,
    this.numberFontSize,
    this.titleFontSize,
    this.footer,
    this.selectedFilterValue,
    this.normalizeBarByItemSum = false,
    this.embedded = false,
    super.key,
  });

  final String title;
  final String number;
  final List<ProgressItemHelper> items;
  final List<ProgressItemHelper>? progressItems;
  final void Function(String label, String? filterValue)? onLegendTap;
  final VoidCallback? onHeaderTap;
  final bool fullWidthBar;
  final double? numberFontSize;
  final double? titleFontSize;
  final Widget? footer;
  final String? selectedFilterValue;
  final bool normalizeBarByItemSum;

  /// When `true` the widget renders as a plain section — no border, no
  /// background, flush horizontal padding — for use inside an existing card.
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final barItems = progressItems ?? items;
    double sumValues = barItems.fold(0, (sum, item) => sum + item.value);
    final int parsedTotal = int.tryParse(number) ?? 0;
    final double effectiveTotal =
        normalizeBarByItemSum ? sumValues : parsedTotal.toDouble();
    bool hasValidTotal = effectiveTotal > 0;
    final legendRows = <List<ProgressItemHelper>>[];
    for (var i = 0; i < items.length; i += 2) {
      legendRows.add(items.sublist(i, i + 2 > items.length ? items.length : i + 2));
    }

    Widget buildLegendItem(ProgressItemHelper item) {
      final isSelected = selectedFilterValue != null && selectedFilterValue == item.filterValue;
      final labelParts = item.label.split('\n');
      final titleText = labelParts.first;
      final valueText =
          labelParts.length > 1 ? labelParts.sublist(1).join('\n') : '';
      final labelWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              titleText,
              style: TextStyle(
                color: AppColors.primaryColor.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
            if (valueText.isNotEmpty)
              Text(
                valueText,
                style: const TextStyle(
                  color: AppColors.themeColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        );
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 1, vertical: 2),
        child: Row(
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
                    onTap: () => onLegendTap!(item.label, item.filterValue),
                    child: labelWidget,
                  )
                : labelWidget,
          ],
        ),
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              color: isSelected
                  ? Colors.white
                  : Colors.transparent,
              border: Border(
                bottom: BorderSide(
                  color: isSelected ? AppColors.themeColor : Colors.transparent,
                  width: 2,
                ),

              ),
            )
      );
    }

    Widget buildLegendLayout() {
      return Column(
        children: legendRows
            .map(
              (row) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: row.length == 2
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.center,
                  children: row.asMap().entries.map((entry) {
                    final index = entry.key;
                    final item = entry.value;
                    final alignment = row.length == 2
                        ? (index == 0
                            ? Alignment.centerLeft
                            : Alignment.centerRight)
                        : Alignment.center;
                    return Expanded(
                      child: Align(
                        alignment: alignment,
                        child: buildLegendItem(item),
                      ),
                    );
                  }).toList(),
                ),
              ),
            )
            .toList(),
      );
    }

    if (fullWidthBar) {
      // Admin billing style: label and value above, bar full width
      final percentList = barItems.map((item) => item.value).toList();
      final percentTotal = percentList.fold(0.0, (a, b) => a + b);
      return Container(
        padding: embedded
            ? const EdgeInsets.symmetric(vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: embedded
            ? null
            : BoxDecoration(
                border: Border.all(color: AppColors.cardBorderColor),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.cardColor,
              ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            onHeaderTap != null
                ? GestureDetector(
                    onTap: onHeaderTap,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              color: const Color(0xff573353),
                              fontWeight: FontWeight.w500,
                              fontSize: titleFontSize ?? 15,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            number,
                            maxLines: 1,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 22,
                              color: AppColors.themeColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: const Color(0xff573353),
                            fontWeight: FontWeight.w500,
                            fontSize: titleFontSize ?? 15,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          number,
                          maxLines: 1,
                          overflow: TextOverflow.fade,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 22,
                            color: AppColors.themeColor,
                            fontWeight: FontWeight.w700,
                          ),
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
                      ? [
                          Expanded(
                              child: Container(color: Colors.grey[300]))
                        ]
                      : [
                          ...barItems.map((item) => Expanded(
                                flex: ((item.value * 1000) ~/ percentTotal),
                                child: Container(color: item.color),
                              )),
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
            buildLegendLayout(),
            if (footer != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.center,
                child: footer!,
              ),
            ],
          ],
        ),
      );
    } else {
      // Original style
      return Container(
        padding: embedded
            ? const EdgeInsets.symmetric(vertical: 8)
            : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: embedded
            ? null
            : BoxDecoration(
                border: Border.all(color: AppColors.cardBorderColor),
                borderRadius: BorderRadius.circular(12),
                color: AppColors.cardColor,
              ),
        child: Row(
          children: [
            onHeaderTap != null
                ? GestureDetector(
                    onTap: onHeaderTap,
                    child: Column(
                      children: [
                        Text(
                          number,
                          style: TextStyle(
                            fontSize: numberFontSize ?? 24,
                            color: AppColors.themeColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            color: const Color(0xff573353),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      Text(
                        number,
                        style: TextStyle(
                          fontSize: numberFontSize ?? 24,
                          color: AppColors.themeColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Manrope',
                          color: const Color(0xff573353),
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
                                    child: Container(color: Colors.grey[300]))
                              ]
                            : [
                                // Use a higher-resolution flex so small values don't round to 0.
                                // If a segment has value > 0, it must have at least 1 flex.
                                ...barItems
                                    .where((item) => item.value > 0)
                                    .map((item) {
                                  final computed =
                                      ((item.value / effectiveTotal) * 1000)
                                          .round();
                                  final flex = computed <= 0 ? 1 : computed;
                                  return Expanded(
                                    flex: flex,
                                    child: Container(color: item.color),
                                  );
                                }),
                                if (!normalizeBarByItemSum &&
                                    sumValues < effectiveTotal)
                                  Expanded(
                                    flex: (() {
                                      final remaining = effectiveTotal - sumValues;
                                      final computed =
                                          ((remaining / effectiveTotal) * 1000)
                                              .round();
                                      return computed <= 0 ? 1 : computed;
                                    })(),
                                    child: Container(color: Colors.grey[300]),
                                  ),
                              ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  buildLegendLayout(),
                  if (footer != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.center,
                      child: footer!,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }
  }
}
