import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// One CSS `inset` box-shadow.
///
/// Flutter's [BoxShadow] only casts outward, but two of this design's three
/// materials are inset: the lit top bevel that makes a raised face read as a
/// solid object, and the recessed well that every input sits in. Every value
/// here maps one-to-one onto the CSS the design ships, so
/// `inset 0 3px 6px rgba(10,28,93,.14)` is
/// `InsetShadow(offset: Offset(0, 3), blur: 6, color: ...)`.
@immutable
class InsetShadow {
  const InsetShadow({
    required this.color,
    this.offset = Offset.zero,
    this.blur = 0,
    this.spread = 0,
  });

  final Color color;
  final Offset offset;
  final double blur;
  final double spread;

  @override
  bool operator ==(Object other) =>
      other is InsetShadow &&
      other.color == color &&
      other.offset == offset &&
      other.blur == blur &&
      other.spread == spread;

  @override
  int get hashCode => Object.hash(color, offset, blur, spread);
}

/// Paints [InsetShadow]s inside a rounded rectangle.
///
/// Blurred insets are drawn by clipping to the shape and filling everything
/// *outside* an offset copy of it with a blurred paint, so the blur bleeds
/// inward from the edge. A zero-blur inset with a [InsetShadow.spread] is drawn
/// as an inside stroke instead, which is exactly what
/// `inset 0 0 0 Npx <color>` means.
class InsetShadowPainter extends CustomPainter {
  const InsetShadowPainter(this.shadows, this.borderRadius);

  final List<InsetShadow> shadows;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (shadows.isEmpty) return;

    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect);

    canvas
      ..save()
      ..clipRRect(rrect);

    for (final shadow in shadows) {
      if (shadow.blur == 0 &&
          shadow.offset == Offset.zero &&
          shadow.spread > 0) {
        // `inset 0 0 0 Npx <color>` — a hairline ring drawn inside the edge.
        canvas.drawRRect(
          rrect.deflate(shadow.spread / 2),
          Paint()
            ..color = shadow.color
            ..style = PaintingStyle.stroke
            ..strokeWidth = shadow.spread,
        );
        continue;
      }

      final paint = Paint()..color = shadow.color;
      if (shadow.blur > 0) {
        // A CSS blur-radius of r is roughly two sigma.
        paint.maskFilter = ui.MaskFilter.blur(
          ui.BlurStyle.normal,
          shadow.blur / 2,
        );
      }

      // Everything outside the shifted, deflated shape, so the blur spills in.
      final outer = Path()..addRect(rect.inflate(size.longestSide + 40));
      final inner = Path()
        ..addRRect(rrect.deflate(shadow.spread).shift(shadow.offset));
      canvas.drawPath(
        Path.combine(PathOperation.difference, outer, inner),
        paint,
      );
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(InsetShadowPainter oldDelegate) =>
      oldDelegate.shadows != shadows ||
      oldDelegate.borderRadius != borderRadius;
}

/// Draws [shadows] over [child], clipped to [borderRadius].
///
/// Use this when a surface only needs its insets on top of a plain background.
/// A surface that stacks its own layers should reach for [InsetShadowPainter]
/// directly, so the insets land above the fill and below the content — the
/// order CSS paints them in.
class InsetShadowBox extends StatelessWidget {
  const InsetShadowBox({
    required this.shadows,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  final List<InsetShadow> shadows;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (shadows.isEmpty) return child;
    return CustomPaint(
      foregroundPainter: InsetShadowPainter(shadows, borderRadius),
      child: child,
    );
  }
}
