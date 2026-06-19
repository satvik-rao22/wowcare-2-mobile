import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// A coloured pill showing a score or computed average (PRD BR-AS-03 colours).
/// Used on student cards, classroom cards, and domain rows.
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({
    super.key,
    required this.score,
    this.label,
    this.dense = false,
  });

  /// Numeric value (1–5 or an average). Null renders a neutral "—" badge.
  final double? score;

  /// Optional leading label (e.g. domain name) shown before the value.
  final String? label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final style = AssessmentUi.badgeStyle(score);
    final valueText = AssessmentAggregation.formatAverage(score);
    return Semantics(
      label: label == null
          ? 'Score $valueText'
          : '$label score $valueText',
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 8 : 10,
          vertical: dense ? 3 : 5,
        ),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: style.border),
        ),
        child: Text(
          label == null ? valueText : '$label  $valueText',
          style: TextStyle(
            color: style.foreground,
            fontWeight: FontWeight.w600,
            fontSize: dense ? 11 : 12.5,
          ),
        ),
      ),
    );
  }
}
