import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';

/// A horizontal two-segment proportion bar (regular vs overtime).
///
/// [regularFraction] is clamped to 0..1. When either side is non-zero it is
/// given a minimum sliver so the colour is always visible. Pure layout — no
/// text — so it composes inside the hero card and inside compact day rows.
class Av2SplitBar extends StatelessWidget {
  const Av2SplitBar({
    super.key,
    required this.regularFraction,
    this.height = 12,
    this.trackColor = Av2Colors.surfaceMuted,
  });

  final double regularFraction;
  final double height;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    final regular = regularFraction.clamp(0.0, 1.0);
    final overtime = 1 - regular;

    // Give a visible sliver to a tiny-but-present segment.
    int regularFlex = (regular * 1000).round();
    int overtimeFlex = (overtime * 1000).round();
    if (overtime > 0 && overtimeFlex < 30) overtimeFlex = 30;
    if (regular > 0 && regularFlex < 30) regularFlex = 30;

    return ClipRRect(
      borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
      child: SizedBox(
        height: height,
        child: Row(
          // Stretch so the childless ColoredBox segments fill the bar height
          // (without this they collapse to zero height and the bar vanishes).
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (regularFlex > 0)
              Expanded(
                flex: regularFlex,
                child: const ColoredBox(color: Av2Colors.barRegular),
              ),
            if (overtimeFlex > 0)
              Expanded(
                flex: overtimeFlex,
                child: const ColoredBox(color: Av2Colors.barOvertime),
              ),
            if (regularFlex == 0 && overtimeFlex == 0)
              Expanded(child: ColoredBox(color: trackColor)),
          ],
        ),
      ),
    );
  }
}

/// A legend dot + label pair, reused under the hero bar.
class Av2LegendItem extends StatelessWidget {
  const Av2LegendItem({
    super.key,
    required this.color,
    required this.text,
    this.textStyle,
  });

  final Color color;
  final String text;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: textStyle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
