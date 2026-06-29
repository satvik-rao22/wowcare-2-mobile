import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// A compact circular gauge for an overall average score (out of 5). The ring
/// sweeps to the value and the centre number counts up on first build, so a
/// student/classroom's standing reads at a glance and feels alive.
class ScoreRing extends StatelessWidget {
  const ScoreRing({
    super.key,
    required this.score,
    this.size = 54,
    this.strokeWidth = 5,
  });

  /// Average out of 5, or null when nothing has been assessed yet.
  final double? score;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final accent = AssessmentUi.scoreAccent(score);
    final target = ((score ?? 0) / 5).clamp(0.0, 1.0);

    return SizedBox(
      width: size,
      height: size,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 750),
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                // value 0 (not null) keeps the track visible without an
                // indeterminate spinner when nothing has been assessed.
                child: CircularProgressIndicator(
                  value: score == null ? 0 : target * t,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  backgroundColor: accent.withValues(alpha: 0.14),
                  valueColor: AlwaysStoppedAnimation<Color>(accent),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    score == null ? '—' : (score! * t).toStringAsFixed(1),
                    style: TextStyle(
                      fontSize: size * 0.30,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: accent,
                    ),
                  ),
                  if (score != null)
                    Text(
                      '/5',
                      style: TextStyle(
                        fontSize: size * 0.18,
                        height: 1.1,
                        fontWeight: FontWeight.w600,
                        color: accent.withValues(alpha: 0.65),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
