import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';

/// How much of a classroom is in today (3S1).
///
/// A ring rather than a bar because the figure inside it is the point: the
/// arc is the context, and it is drawn in the student teal because what it
/// counts is students.
class RatioRing extends StatelessWidget {
  const RatioRing({required this.present, required this.total, super.key});

  final int present;
  final int total;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final fraction = total == 0 ? 0.0 : (present / total).clamp(0.0, 1.0);

    return SizedBox.square(
      dimension: DashboardSizes.ratioRing,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          CustomPaint(
            size: const Size.square(DashboardSizes.ratioRing),
            painter: _RingPainter(fraction: fraction, colours: c),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '$present',
                style: DashboardTextStyles.ratioRingNumber.copyWith(
                  color: c.ink,
                ),
              ),
              Text(
                DashboardStrings.ofIn(total).toUpperCase(),
                style: DashboardTextStyles.ratioRingCaption.copyWith(
                  color: c.student,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({required this.fraction, required this.colours});

  final double fraction;
  final Colourway colours;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = DashboardSizes.ratioRingStroke;
    final rect = Offset.zero & size;
    final circle = rect.deflate(stroke / 2);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = colours.well;
    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = colours.student;

    canvas
      ..drawArc(circle, 0, 2 * math.pi, false, track)
      ..drawArc(circle, -math.pi / 2, 2 * math.pi * fraction, false, arc);
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) =>
      oldDelegate.fraction != fraction || oldDelegate.colours != colours;
}
