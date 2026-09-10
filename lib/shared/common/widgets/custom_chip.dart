import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

class CustomChip extends StatefulWidget {
  const CustomChip({
    required this.label,
    required this.labelStyle,
    this.widget,
    this.color,
    this.gradient,
    super.key,
  });

  final String label;
  final TextStyle labelStyle;
  final Widget? widget;
  final Color? color;

  /// Kept for source compatibility. Rule 3 of the design language forbids a
  /// gradient, so a caller that still passes one gets its first stop as a
  /// flat fill.
  final LinearGradient? gradient;

  @override
  State<CustomChip> createState() => _CustomChipState();
}

class _CustomChipState extends State<CustomChip> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color:
            widget.color ??
            (widget.gradient != null
                ? widget.gradient!.colors.first
                : AppPalette.surfaceCard),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.label, style: widget.labelStyle),
          if (widget.widget != null) const SizedBox(width: 8),
          if (widget.widget != null) widget.widget!,
        ],
      ),
    );
  }
}
