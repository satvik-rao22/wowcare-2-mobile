import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_scale.dart';

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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            // Wrap so the five buttons never overflow on narrow phones.
            return Wrap(
              spacing: 6,
              runSpacing: 6,
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
                    compact: compact,
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
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.themeColor,
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
    required this.compact,
    required this.onTap,
  });

  final int score;
  final bool selected;
  final bool disabled;
  final bool compact;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 36.0 : 44.0;
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: Material(
        color: selected ? AppColors.themeColor.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.themeColor : Colors.grey.shade300,
                width: selected ? 2 : 1,
              ),
            ),
            child: Text(
              '$score',
              style: TextStyle(
                fontSize: compact ? 14 : 16,
                fontWeight: FontWeight.w700,
                color: selected ? AppColors.themeColor : Colors.grey.shade700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
