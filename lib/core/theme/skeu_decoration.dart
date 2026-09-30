/// A [Decoration] that can paint the whole flat skeuomorphic material in one
/// object: flat fill, ambient shadow below, **inset** shadows inside, and a
/// hairline border.
///
/// [BoxDecoration] cannot do the inset half, which is most of the language —
/// the lit top bevel and the recessed well are both inset shadows. Splitting
/// them out would mean wrapping every call site in an extra widget, which
/// would change the widget tree; a `Decoration` does not, so a widget swaps
/// its `decoration:` and nothing about its content moves.
///
/// Layout matches [BoxDecoration] exactly, border included, so substituting
/// one for the other never shifts a pixel of content.
///
/// Build these with [AppSurfaces] rather than by hand.
library;

import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:wowcare/core/theme/app_elevation.dart';
import 'package:wowcare/core/theme/skeu_inset_paint.dart';

@immutable
class SkeuDecoration extends Decoration {
  const SkeuDecoration({
    this.color,
    this.borderRadius = BorderRadius.zero,
    this.border,
    this.boxShadow = const <BoxShadow>[],
    this.insets = const <AppInset>[],
    this.shape = BoxShape.rectangle,
  });

  /// The flat fill. One colour: never a gradient.
  final Color? color;

  /// Ignored when [shape] is [BoxShape.circle].
  final BorderRadius borderRadius;

  /// Drawn inside the shape, exactly as [BoxDecoration] draws its own — so
  /// a one-sided [Border] works too, which is how a bar gets its top
  /// hairline without a ring round the rest of it.
  final BoxBorder? border;

  /// Shadows cast outward: the ambient shadow below, and the solid rim.
  final List<BoxShadow> boxShadow;

  /// Shadows cast inward: the lit top bevel, and the well.
  final List<AppInset> insets;

  final BoxShape shape;

  @override
  EdgeInsetsGeometry get padding => border?.dimensions ?? EdgeInsets.zero;

  @override
  bool get isComplex => boxShadow.isNotEmpty || insets.isNotEmpty;

  SkeuDecoration copyWith({
    Color? color,
    BorderRadius? borderRadius,
    BoxBorder? border,
    List<BoxShadow>? boxShadow,
    List<AppInset>? insets,
    BoxShape? shape,
  }) => SkeuDecoration(
    color: color ?? this.color,
    borderRadius: borderRadius ?? this.borderRadius,
    border: border ?? this.border,
    boxShadow: boxShadow ?? this.boxShadow,
    insets: insets ?? this.insets,
    shape: shape ?? this.shape,
  );

  RRect _rrect(Rect rect) => shape == BoxShape.circle
      ? RRect.fromRectAndRadius(rect, Radius.circular(rect.shortestSide / 2))
      : borderRadius.toRRect(rect);

  @override
  Path getClipPath(Rect rect, TextDirection textDirection) =>
      Path()..addRRect(_rrect(rect));

  @override
  bool hitTest(Size size, Offset position, {TextDirection? textDirection}) =>
      _rrect(Offset.zero & size).contains(position);

  @override
  SkeuDecoration? lerpFrom(Decoration? a, double t) => a is SkeuDecoration
      ? _lerp(a, this, t)
      : (a == null ? _lerp(null, this, t) : null);

  @override
  SkeuDecoration? lerpTo(Decoration? b, double t) => b is SkeuDecoration
      ? _lerp(this, b, t)
      : (b == null ? _lerp(this, null, t) : null);

  static SkeuDecoration _lerp(SkeuDecoration? a, SkeuDecoration? b, double t) {
    final SkeuDecoration from = a ?? const SkeuDecoration();
    final SkeuDecoration to = b ?? const SkeuDecoration();
    return SkeuDecoration(
      color: Color.lerp(from.color, to.color, t),
      borderRadius:
          BorderRadius.lerp(from.borderRadius, to.borderRadius, t) ??
          BorderRadius.zero,
      border: BoxBorder.lerp(from.border, to.border, t),
      boxShadow:
          BoxShadow.lerpList(from.boxShadow, to.boxShadow, t) ??
          const <BoxShadow>[],
      // Insets are a discrete recipe, not a ramp: swap them at the midpoint
      // rather than interpolating a bevel into a well.
      insets: t < .5 ? from.insets : to.insets,
      shape: t < .5 ? from.shape : to.shape,
    );
  }

  @override
  BoxPainter createBoxPainter([VoidCallback? onChanged]) => _SkeuPainter(this);

  @override
  bool operator ==(Object other) =>
      other is SkeuDecoration &&
      other.color == color &&
      other.borderRadius == borderRadius &&
      other.border == border &&
      listEquals(other.boxShadow, boxShadow) &&
      listEquals(other.insets, insets) &&
      other.shape == shape;

  @override
  int get hashCode => Object.hash(
    color,
    borderRadius,
    border,
    Object.hashAll(boxShadow),
    Object.hashAll(insets),
    shape,
  );
}

class _SkeuPainter extends BoxPainter {
  _SkeuPainter(this.d);

  final SkeuDecoration d;

  @override
  void paint(Canvas canvas, Offset offset, ImageConfiguration configuration) {
    final Size size = configuration.size ?? Size.zero;
    if (size.isEmpty) return;
    final Rect rect = offset & size;
    final RRect rrect = d._rrect(rect);

    // CSS paint order: outer shadows, fill, inset shadows, border.
    for (final BoxShadow s in d.boxShadow) {
      final Paint p = Paint()..color = s.color;
      if (s.blurRadius > 0) {
        p.maskFilter = ui.MaskFilter.blur(ui.BlurStyle.normal, s.blurSigma);
      }
      canvas.drawRRect(rrect.shift(s.offset).inflate(s.spreadRadius), p);
    }

    if (d.color != null) canvas.drawRRect(rrect, Paint()..color = d.color!);

    // Shared with SkeuInnerShadow, and cached: see skeu_inset_paint.dart for
    // why a blurred inset must not be drawn from scratch on every frame.
    paintSkeuInsets(
      canvas,
      rrect,
      d.insets,
      devicePixelRatio:
          configuration.devicePixelRatio ??
          ui.PlatformDispatcher.instance.implicitView?.devicePixelRatio ??
          1,
    );

    d.border?.paint(
      canvas,
      rect,
      shape: d.shape,
      borderRadius: d.shape == BoxShape.circle ? null : d.borderRadius,
    );
  }
}
