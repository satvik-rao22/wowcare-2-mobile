import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';

/// A card face outlined in a dashed hairline: the "Add a parent" and "Add a
/// document" rows on 5c, and the not-started-yet rows on 5a.
///
/// The dash says the same thing in both places: this is a placeholder for
/// something that is not on the record yet. Flutter's [Border] has no dash,
/// so the outline is painted; everything else is the ordinary card face.
class DashedOutlineBox extends StatelessWidget {
  const DashedOutlineBox({
    required this.child,
    this.padding,
    this.radius = AppRadii.card,
    this.onTap,
    this.color,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final VoidCallback? onTap;

  /// Defaults to the dashed-line colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final box = CustomPaint(
      painter: _DashedBorderPainter(
        color: color ?? c.dashedLine,
        radius: radius,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: padding == null
            ? child
            : Padding(padding: padding!, child: child),
      ),
    );

    if (onTap == null) return box;
    return Pressable.surface(onTap: onTap, child: box);
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color, required this.radius});

  final Color color;
  final double radius;

  /// Six on, four off: long enough to read as a dash at a hairline weight.
  static const double _dash = 6;
  static const double _gap = 4;
  static const double _stroke = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, Radius.circular(radius)),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    for (final metric in outline.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = (start + _dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(start, end), paint);
        start = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter old) =>
      old.color != color || old.radius != radius;
}
