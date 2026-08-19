import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// One band of a [CustomStatBarCard]'s bar, and its legend entry.
class ProgressItemHelper {
  const ProgressItemHelper({
    required this.label,
    required this.value,
    required this.color,
    this.filterValue,
  });

  final String label;
  final double value;
  final Color color;
  final String? filterValue;
}

/// A "total, broken down" card: the headline figure beside a proportional bar
/// and its dotted legend.
///
/// In the skeuomorphic language the bar is a recessed trough with the bands
/// sitting flush inside it, so the whole card reads as one gauge. Tapping a
/// legend entry still filters the list behind it; the selected entry keeps a
/// teal underline.
///
/// Two shapes, unchanged from before: the default puts the figure on the left,
/// and [fullWidthBar] stacks a title/value row over a full-width trough.
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

  /// When `true` the widget renders as a plain section — no panel, flush
  /// horizontal padding — for use inside an existing card.
  final bool embedded;

  static const _trackRadius = 9.0;
  static const _trackHeight = 22.0;

  @override
  Widget build(BuildContext context) {
    final content = fullWidthBar ? _buildFullWidth() : _buildInline();
    if (embedded) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: content,
      );
    }
    return SkeuPanel(
      radius: SkeuRadius.xxl,
      padding: const EdgeInsets.all(16),
      child: content,
    );
  }

  // ── The figure beside the bar (student / staff / classroom summaries) ──────
  Widget _buildInline() {
    final headline = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          style: SkeuText.small().copyWith(
            height: 1.3,
            fontSize: titleFontSize,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          number,
          style: TextStyle(
            fontFamily: SkeuText.family,
            fontSize: numberFontSize ?? 30,
            fontWeight: SkeuText.weightBold,
            color: SkeuColors.ink,
            letterSpacing: (numberFontSize ?? 30) * -0.02,
          ),
        ),
      ],
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 82,
          child: onHeaderTap != null
              ? GestureDetector(onTap: onHeaderTap, child: headline)
              : headline,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTrack(),
              const SizedBox(height: 10),
              _buildLegend(),
              if (footer != null) ...[
                const SizedBox(height: 8),
                Align(alignment: Alignment.center, child: footer!),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Title and value above a full-width bar (billing / accounting) ──────────
  Widget _buildFullWidth() {
    final header = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: SkeuText.field(
              weight: SkeuText.weightHeading,
            ).copyWith(fontSize: titleFontSize ?? 15),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            number,
            maxLines: 1,
            overflow: TextOverflow.fade,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: SkeuText.family,
              fontSize: numberFontSize ?? 22,
              fontWeight: SkeuText.weightBold,
              color: SkeuColors.ink,
            ),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        onHeaderTap != null
            ? GestureDetector(onTap: onHeaderTap, child: header)
            : header,
        const SizedBox(height: 12),
        _buildTrack(),
        const SizedBox(height: 12),
        _buildLegend(),
        if (footer != null) ...[
          const SizedBox(height: 8),
          Align(alignment: Alignment.center, child: footer!),
        ],
      ],
    );
  }

  /// The recessed trough. Bands are laid out on a 1000-unit flex so a single
  /// unit of a large total still gets a visible sliver, and the unfilled
  /// remainder of the total stays as empty trough rather than a grey band.
  Widget _buildTrack() {
    final barItems = progressItems ?? items;
    final sumValues = barItems.fold<double>(0, (sum, item) => sum + item.value);
    final parsedTotal = double.tryParse(number.replaceAll(',', '')) ?? 0;
    final effectiveTotal = normalizeBarByItemSum ? sumValues : parsedTotal;
    final hasValidTotal = effectiveTotal > 0;

    return SkeuWell(
      height: _trackHeight,
      radius: _trackRadius,
      gradient: SkeuSurfaces.sunken,
      insets: SkeuElevation.wellSm,
      child: !hasValidTotal
          ? const SizedBox.shrink()
          : Row(
              children: [
                for (final item in barItems.where((i) => i.value > 0))
                  Expanded(
                    flex: (((item.value / effectiveTotal) * 1000).round())
                        .clamp(1, 1 << 30),
                    child: ColoredBox(color: item.color),
                  ),
                if (!normalizeBarByItemSum && sumValues < effectiveTotal)
                  Expanded(
                    flex:
                        ((((effectiveTotal - sumValues) / effectiveTotal) *
                                    1000)
                                .round())
                            .clamp(1, 1 << 30),
                    child: const SizedBox.shrink(),
                  ),
              ],
            ),
    );
  }

  Widget _buildLegend() {
    final legendRows = <List<ProgressItemHelper>>[];
    for (var i = 0; i < items.length; i += 2) {
      legendRows.add(
        items.sublist(i, i + 2 > items.length ? items.length : i + 2),
      );
    }

    return Column(
      children: [
        for (var r = 0; r < legendRows.length; r++)
          Padding(
            padding: EdgeInsets.only(
              bottom: r == legendRows.length - 1 ? 0 : 8,
            ),
            child: Row(
              children: [
                for (final item in legendRows[r])
                  Expanded(child: _buildLegendItem(item)),
                if (legendRows[r].length == 1 && items.length > 1)
                  const Expanded(child: SizedBox.shrink()),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLegendItem(ProgressItemHelper item) {
    final isSelected =
        selectedFilterValue != null && selectedFilterValue == item.filterValue;
    // A label may carry its value on a second line ("Net Paid\n$39,400").
    final labelParts = item.label.split('\n');
    final labelWidget = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          labelParts.first,
          style: SkeuText.small(
            color: SkeuColors.ink.withValues(alpha: .8),
          ),
        ),
        if (labelParts.length > 1)
          Text(
            labelParts.sublist(1).join('\n'),
            style: SkeuText.small(
              color: SkeuColors.teal700,
              weight: SkeuText.weightBold,
            ),
          ),
      ],
    );

    return Container(
      padding: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isSelected ? SkeuColors.teal600 : Colors.transparent,
            width: 2,
          ),
        ),
      ),
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
          const SizedBox(width: 7),
          Flexible(
            child: onLegendTap != null
                ? GestureDetector(
                    onTap: () => onLegendTap!(item.label, item.filterValue),
                    child: labelWidget,
                  )
                : labelWidget,
          ),
        ],
      ),
    );
  }
}
