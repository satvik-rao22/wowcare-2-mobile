import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// Compact per-domain score tile used on student and classroom cards: a short
/// domain label over its average score, tinted by the score-band colour
/// (green ≥ 4, amber 2–3, red < 2, indigo when unscored).
class DomainScoreTile extends StatelessWidget {
  const DomainScoreTile({
    super.key,
    required this.shortLabel,
    required this.score,
  });

  final String shortLabel;

  /// Domain average out of 5, or null when nothing is scored ("–").
  final double? score;

  @override
  Widget build(BuildContext context) {
    final style = AssessmentUi.badgeStyle(score);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            shortLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w700,
              color: style.foreground,
            ),
          ),
          Text(
            score == null ? '–' : score!.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 12,
              height: 1.1,
              fontWeight: FontWeight.w800,
              color: style.foreground,
            ),
          ),
        ],
      ),
    );
  }
}
