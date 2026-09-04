import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';

/// The dashed panel that stands where a list would be when a filter left
/// nothing: "Every classroom is covered" (7a), "Nobody matches that" (7c).
///
/// A dashed outline rather than a card, because nothing here is a thing you
/// can press: it is the shape of the row that is not there.
class DashedPanel extends StatelessWidget {
  const DashedPanel({
    required this.title,
    this.message,
    this.padding = ClassroomsSizes.coveredPad,
    super.key,
  });

  final String title;
  final String? message;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return CustomPaint(
      painter: _DashedBorderPainter(color: c.dashedLine),
      child: Padding(
        padding: padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: ClassroomsSizes.coveredGap,
          children: <Widget>[
            Text(
              title,
              style: ClassroomsTextStyles.panelTitle.copyWith(color: c.ink),
              textAlign: TextAlign.center,
            ),
            if (message != null)
              Text(
                message!,
                style: ClassroomsTextStyles.panelBody.copyWith(color: c.ink3),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}

/// Flutter has no dashed border, so the card radius is walked by hand.
class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          const Radius.circular(AppRadii.card),
        ),
      );

    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + ClassroomsSizes.dashLength;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + ClassroomsSizes.dashGap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.color != color;
}
