import 'package:flutter/material.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// A white pill showing a scope selector (classroom / period / school): a tinted
/// icon, an uppercase eyebrow label, the current value, and an optional trailing
/// affordance (chevron when tappable, lock when fixed). Used in the filter rows
/// across the Students, Classrooms and School tabs.
class AssessmentScopeChip extends StatelessWidget {
  const AssessmentScopeChip({
    super.key,
    required this.icon,
    required this.value,
    this.eyebrow,
    this.iconColor,
    this.onTap,
    this.locked = false,
    this.expand = false,
  });

  final IconData icon;
  final String value;

  /// Optional uppercase label above the value (e.g. "CLASSROOM").
  final String? eyebrow;
  final Color? iconColor;
  final VoidCallback? onTap;

  /// Shows a lock glyph instead of a chevron (e.g. staff can't change classroom).
  final bool locked;

  /// Whether the chip should expand to fill available width (Flexible parent).
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final color = iconColor ?? AssessmentUi.brand;
    final chip = Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1B2559).withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Flexible(
                fit: expand ? FlexFit.tight : FlexFit.loose,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (eyebrow != null)
                      Text(
                        eyebrow!,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: AssessmentUi.inkMuted,
                        ),
                      ),
                    Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AssessmentUi.ink,
                      ),
                    ),
                  ],
                ),
              ),
              if (locked) ...[
                const SizedBox(width: 8),
                const Icon(Icons.lock_outline_rounded,
                    size: 14, color: Color(0xFFC0BACD)),
              ] else if (onTap != null) ...[
                const SizedBox(width: 8),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    size: 18, color: AssessmentUi.inkMuted),
              ],
            ],
          ),
        ),
      ),
    );
    return expand ? chip : IntrinsicWidth(child: chip);
  }
}
