import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The app-wide checkbox, plus its optional label.
///
/// In the skeuomorphic language an unchecked box is a small recessed well and a
/// checked one fills with the pink recommended-action face and a tick — the
/// same object the design uses for "Remember me" on the sign-in sheet. All
/// existing parameters are kept so the many selection lists that use this are
/// unchanged; [borderColor] and [usingInkwell] no longer affect the rendering
/// because the well draws its own rim and the whole row is the tap target.
class CustomCheckbox extends StatelessWidget {
  const CustomCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.labelStyle,
    this.scale,
    this.borderColor,
    this.usingInkwell = false,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final TextStyle? labelStyle;

  /// Scales the box off its 22px base, as the old [Checkbox] scale did.
  final double? scale;

  /// Retained for call-site compatibility — the well paints its own rim.
  final Color? borderColor;

  /// Retained for call-site compatibility — the row is always the tap target.
  final bool usingInkwell;

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = onChanged != null;
    final double side = 22 * (scale ?? 1.2) / 1.2;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isInteractive ? () => onChanged!(!value) : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Opacity(
            opacity: isInteractive ? 1 : .55,
            child: SkeuCheckbox(
              value: value,
              size: side,
              onChanged: isInteractive ? (v) => onChanged!(v) : null,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label!,
                style:
                    labelStyle ??
                    SkeuText.small(
                      color: SkeuColors.ink,
                      weight: SkeuText.weightMedium,
                    ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
