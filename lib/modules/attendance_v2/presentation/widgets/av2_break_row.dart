import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../core/utils/av2_date_formatter.dart';
import '../../core/utils/av2_duration_formatter.dart';

/// A muted divider row shown between two sessions to represent the break the
/// staff took (signed out, then back in later).
class Av2BreakRow extends StatelessWidget {
  const Av2BreakRow({
    super.key,
    required this.minutes,
    required this.start,
    required this.end,
  });

  final int minutes;
  final DateTime start;
  final DateTime end;

  @override
  Widget build(BuildContext context) {
    final window =
        '${Av2DateFormatter.compactTime(start)}–${Av2DateFormatter.compactTime(end)}';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const SizedBox(width: 24, child: _DashedConnector()),
          const SizedBox(width: 4),
          const Icon(Icons.free_breakfast_outlined,
              size: 15, color: Av2Colors.breakTime),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${Av2DurationFormatter.hm(minutes)} break · $window',
              style: Av2Text.caption.copyWith(color: Av2Colors.breakTime),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Small vertical dashed line that visually links the two sessions a break
/// sits between.
class _DashedConnector extends StatelessWidget {
  const _DashedConnector();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        height: 14,
        child: CustomPaint(painter: _DashPainter(), size: const Size(1, 14)),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Av2Colors.borderStrong
      ..strokeWidth = 1;
    const dash = 2.5;
    const gap = 2.5;
    double y = 0;
    final x = size.width / 2;
    while (y < size.height) {
      canvas.drawLine(Offset(x, y), Offset(x, y + dash), paint);
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
