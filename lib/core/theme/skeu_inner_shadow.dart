/// Paints CSS-style `inset` box-shadows, which Flutter's [BoxShadow] cannot do.
///
/// Ported from the skeuomorphic kit on `wowcare-skeumorph`. The technique is
/// what was worth keeping; the token values there are a generation stale, so
/// the recipes come from [AppElevation] instead.
///
/// The flat material leans on inset shadows for two of its four devices: the
/// lit top bevel that makes a panel read as a solid object, and the recessed
/// well that every input sits in. Without them a flat fill is just a
/// rectangle.
///
/// Blurred insets are drawn by clipping to the shape and filling everything
/// *outside* an offset copy of it with a blurred paint, so the blur bleeds
/// inward from the edge. Zero-blur insets with a spread are drawn as an
/// inside stroke, matching `inset 0 0 0 Npx <color>` exactly.
library;

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:wowcare/core/theme/app_elevation.dart';
import 'package:wowcare/core/theme/app_radius.dart';

/// Wraps [child] and paints [shadows] inside [borderRadius], over the child's
/// own background but under its content — exactly where CSS orders them.
class SkeuInnerShadow extends StatelessWidget {
  const SkeuInnerShadow({
    required this.shadows,
    required this.borderRadius,
    required this.child,
    super.key,
  });

  final List<AppInset> shadows;
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
/// own layers can slot the insets in at the right depth.
class SkeuInsetPainter extends CustomPainter {
  const SkeuInsetPainter(this.shadows, this.borderRadius);

  final List<AppInset> shadows;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final RRect rrect = borderRadius.toRRect(rect);

    canvas.save();
    canvas.clipRRect(rrect);

    for (final AppInset s in shadows) {
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

      final Paint paint = Paint()..color = s.color;
      if (s.blur > 0) {
        // CSS blur-radius r is roughly 2 sigma.
        paint.maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, s.blur / 2);
      }

      // Everything outside the shifted/deflated shape, so the blur spills in.
      final Path outer = Path()..addRect(rect.inflate(size.longestSide + 40));
      final Path inner = Path()
        ..addRRect(rrect.deflate(s.spread).shift(s.offset));
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

/// The recess a text field sits in.
///
/// An `InputDecoration` paints its own fill and border and has no way to add
/// an inset shadow, so a field on its own is a flat cool rectangle: the right
/// colour with none of the depth. This paints the well's inset over the
/// field's fill, which is the whole difference between a box laid on the
/// surface and one cut into it.
///
/// Wraps rather than replaces, so the field keeps its own hint, prefix,
/// suffix, focus ring and error border, and its validation message still
/// renders where the framework puts it.
///
/// ```dart
/// SkeuFieldWell(
///   radius: 8,
///   child: TextFormField(decoration: AppSurfaces.fieldDecoration(radius: 8)),
/// )
/// ```
class SkeuFieldWell extends StatelessWidget {
  const SkeuFieldWell({
    required this.child,
    this.radius = AppRadius.lg,
    super.key,
  });

  final Widget child;

  /// Must match the radius the field's own decoration uses, or the inset
  /// will not follow its corners.
  final double radius;

  @override
  Widget build(BuildContext context) => SkeuInnerShadow(
    // The full well, not the shallow one: the shadow from the top edge is
    // only half of it. The lit line along the bottom is what reads as an
    // edge you are looking *into* rather than a patch of shading.
    shadows: AppElevation.well,
    borderRadius: BorderRadius.circular(radius),
    child: child,
  );
}
