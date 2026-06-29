import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_scale.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// The 1–5 scale selector (PRD §12, §21.1). Five buttons; the selected one is
/// highlighted. Accessible: each button carries an aria-style semantics label
/// ("Score 3 - Intermediate") and announces its selected state; keyboard focus
/// traversal works via the underlying [InkWell]s.
class AssessmentScaleSelector extends StatelessWidget {
  const AssessmentScaleSelector({
    super.key,
    required this.value,
    required this.onChanged,
    this.disabled = false,
    this.compact = false,
  });

  final int? value;
  final ValueChanged<int> onChanged;
  final bool disabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final buttonSize = AssessmentUi.scaleButtonSize(width, compact: compact);
    final spacing = AssessmentUi.wrapSpacing(width);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Wrap so the five buttons never overflow on narrow phones.
            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: AssessmentScale.values.map((score) {
                final selected = value == score;
                return Semantics(
                  button: true,
                  selected: selected,
                  label: 'Score $score - ${AssessmentScale.labelFor(score)}',
                  child: _ScaleButton(
                    score: score,
                    selected: selected,
                    disabled: disabled,
                    size: buttonSize,
                    onTap: disabled ? null : () => onChanged(score),
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AssessmentScale.labelFor(AssessmentScale.min),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
            Text(
              AssessmentScale.labelFor(AssessmentScale.max),
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
        if (value != null) ...[
          const SizedBox(height: 4),
          Text(
            AssessmentScale.labelFor(value),
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: AssessmentUi.scaleColor(value!),
            ),
          ),
        ],
      ],
    );
  }
}

class _ScaleButton extends StatelessWidget {
  const _ScaleButton({
    required this.score,
    required this.selected,
    required this.disabled,
    required this.size,
    required this.onTap,
  });

  final int score;
  final bool selected;
  final bool disabled;
  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // Number scales with the button so it stays proportionate on web.
    final fontSize = size * 0.34;
    // Each point carries its own meaning-colour (1 red … 5 green); selecting it
    // fills with that colour, so the scale reads like a traffic-light gradient.
    final color = AssessmentUi.scaleColor(score);
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: AnimatedScale(
        scale: selected ? 1.08 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutBack,
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              width: size,
              height: size,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected
                    ? color
                    : color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? color : color.withValues(alpha: 0.40),
                  width: selected ? 2 : 1.2,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.40),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                '$score',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
