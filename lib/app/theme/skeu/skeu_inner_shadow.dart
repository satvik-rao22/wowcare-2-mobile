import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import 'skeu_tokens.dart';

/// Paints CSS-style `inset` box-shadows, which Flutter's [BoxShadow] cannot do.
///
/// The skeuomorphic language leans on inset shadows for two of its three
/// materials: the lit top bevel that makes a panel read as a solid object, and
/// the recessed well that every input sits in. Both are ported verbatim from
/// the design system's `--bevel-*` / `--well-*` tokens, so this painter is what
/// makes those tokens real.
///
/// Blurred insets are drawn by clipping to the shape and filling everything
/// *outside* an offset copy of it with a blurred paint, so the blur bleeds
/// inward from the edge. Zero-blur insets with a [SkeuInset.spread] are drawn
/// as an inside stroke, matching `inset 0 0 0 Npx <color>` exactly.
class SkeuInnerShadow extends StatelessWidget {
  const SkeuInnerShadow({
    required this.shadows,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  final List<SkeuInset> shadows;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (shadows.isEmpty) return child;
    return CustomPaint(
      foregroundPainter: SkeuInsetPainter(shadows, borderRadius),
      child: child,
    );
  }
}

/// The painter behind [SkeuInnerShadow]. Exposed so a surface that stacks its
/// own layers (gloss, content) can slot the insets in at the right depth:
/// above the background fill, below the content, exactly as CSS orders them.
class SkeuInsetPainter extends CustomPainter {
  const SkeuInsetPainter(this.shadows, this.borderRadius);

  final List<SkeuInset> shadows;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    canvas.save();
    canvas.clipRRect(rrect);

    for (final s in shadows) {
      if (s.blur == 0 && s.offset == Offset.zero && s.spread > 0) {
        // `inset 0 0 0 Npx <color>` — a hairline ring drawn inside the edge.
        canvas.drawRRect(
          rrect.deflate(s.spread / 2),
          Paint()
            ..color = s.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = s.spread,
        );
        continue;
      }

      final paint = Paint()..color = s.color;
      if (s.blur > 0) {
        // CSS blur-radius r is roughly 2 sigma.
        paint.maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, s.blur / 2);
      }

      // Everything outside the shifted/deflated shape, so the blur spills in.
      final outer = Path()..addRect(rect.inflate(size.longestSide + 40));
      final inner = Path()..addRRect(rrect.deflate(s.spread).shift(s.offset));
      canvas.drawPath(
        Path.combine(PathOperation.difference, outer, inner),
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(SkeuInsetPainter old) =>
      old.shadows != shadows || old.borderRadius != borderRadius;
}
