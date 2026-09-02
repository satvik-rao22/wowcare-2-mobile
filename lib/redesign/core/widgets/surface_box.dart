import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/painters/inset_shadow_painter.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';

/// Renders a [Surface]: its fill and outer shadows, then what is lit inside
/// it, then the content.
///
/// That order is the whole point. CSS paints an inset shadow above the
/// background and below the content, so the painter goes behind the child
/// rather than over it — a well's 6px inset blur laid over its own label would
/// grey the text out.
class SurfaceBox extends StatelessWidget {
  const SurfaceBox({
    required this.surface,
    this.child,
    this.padding,
    this.width,
    this.height,
    this.alignment,
    this.clipContent = false,
    super.key,
  });

  final Surface surface;
  final Widget? child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  /// Clip the content to the surface's radius. Off by default because it costs
  /// a save layer; turn it on for images, troughs and anything that would
  /// otherwise paint past the corner.
  final bool clipContent;

  @override
  Widget build(BuildContext context) {
    Widget? content = child;

    if (padding != null && content != null) {
      content = Padding(padding: padding!, child: content);
    }
    if (clipContent && content != null) {
      content = ClipRRect(borderRadius: surface.borderRadius, child: content);
    }
    if (surface.insets.isNotEmpty) {
      content = CustomPaint(
        painter: InsetShadowPainter(surface.insets, surface.borderRadius),
        child: content ?? const SizedBox.expand(),
      );
    }

    return Container(
      width: width,
      height: height,
      alignment: alignment,
      decoration: surface.decoration,
      child: content,
    );
  }
}
