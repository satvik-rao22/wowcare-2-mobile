import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/features/staff/staff_sizes.dart';
import 'package:wowcare/redesign/features/staff/staff_text_styles.dart';

/// The pink "Add a document" key at the foot of 6c's Documents tab: a card's
/// face inside a dashed rim, so it reads as a slot waiting to be filled
/// rather than as the screen's one action.
///
/// Flutter has no dashed border, so the rim is drawn by [_DashedRimPainter],
/// which walks the rounded rectangle and lays a dash along it.
class DashedKey extends StatelessWidget {
  const DashedKey({
    required this.label,
    required this.icon,
    required this.onTap,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      label: label,
      child: Pressable.surface(
        onTap: onTap,
        child: CustomPaint(
          painter: _DashedRimPainter(color: c.dashedLine),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.card,
              borderRadius: AppRadii.cardR,
            ),
            child: Padding(
              padding: StaffSizes.dashedKeyPad,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: StaffSizes.dashedKeyGap,
                children: <Widget>[
                  Icon(icon, size: StaffSizes.dashedKeyGlyph, color: c.pink),
                  Text(
                    label,
                    style: StaffTextStyles.dashedKey.copyWith(color: c.pink),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A dashed rounded rectangle, laid on the outside of the child.
class _DashedRimPainter extends CustomPainter {
  const _DashedRimPainter({required this.color});

  final Color color;

  static const double _dash = 5;
  static const double _gap = 4;
  static const double _stroke = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadii.card),
        ),
      );
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke;

    for (final metric in path.computeMetrics()) {
      var start = 0.0;
      while (start < metric.length) {
        final end = start + _dash;
        canvas.drawPath(
          metric.extractPath(start, end.clamp(0, metric.length)),
          paint,
        );
        start = end + _gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedRimPainter oldDelegate) =>
      oldDelegate.color != color;
}
