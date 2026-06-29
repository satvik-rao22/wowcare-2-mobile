import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_scale.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// A row of five equal-width 1–5 scale buttons (the redesign's scoring control).
/// The selected point fills with its band colour and lifts; the rest sit as
/// tinted neutrals. Used by the domain quick-set and each milestone card.
class ScaleButtonRow extends StatelessWidget {
  const ScaleButtonRow({
    super.key,
    required this.value,
    required this.onPick,
    this.height = 48,
  });

  final int? value;
  final ValueChanged<int> onPick;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: AssessmentScale.values.map((score) {
        final selected = value == score;
        final color = AssessmentUi.scaleColor(score);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: score == AssessmentScale.max ? 0 : 7),
            child: Semantics(
              button: true,
              selected: selected,
              label: 'Score $score - ${AssessmentScale.labelFor(score)}',
              child: Material(
                color: selected ? color : const Color(0xFFF4F2FA),
                borderRadius: BorderRadius.circular(13),
                child: InkWell(
                  onTap: () => onPick(score),
                  borderRadius: BorderRadius.circular(13),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: height,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: selected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.4),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ]
                          : null,
                    ),
                    child: Text(
                      '$score',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
                        color: selected ? Colors.white : const Color(0xFFB0AABE),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
