import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// A read-only badge: a soft tinted plate with a lit bevel, carrying a short
/// label and optionally a trailing widget.
///
/// Pill-shaped in the skeuomorphic language, because a chip is a bead of
/// information rather than a rectangle of colour. [color] / [gradient] still
/// choose its wash, so existing call sites keep their own tone.
class CustomChip extends StatelessWidget {
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
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return SkeuPanel(
      radius: SkeuRadius.pill,
      shadows: const [],
      color: gradient == null ? (color ?? SkeuColors.teal50) : null,
      gradient: gradient,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: labelStyle),
          if (widget != null) ...[const SizedBox(width: 8), widget!],
        ],
      ),
    );
  }
}
