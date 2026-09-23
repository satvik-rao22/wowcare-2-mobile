import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_haptics.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

class CustomCancelButton extends StatelessWidget {
  const CustomCancelButton({
    this.cancelButtonLabel,
    this.onPressedCancel,
    this.gradientLabel = false,
    super.key,
  });

  final String? cancelButtonLabel;
  final void Function()? onPressedCancel;

  /// Kept for source compatibility. It used to paint the label with the
  /// primary gradient; there are no gradients any more, so both states now
  /// render the same flat navy label.
  final bool gradientLabel;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: AppColors.primaryColor,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    final label = Text(cancelButtonLabel ?? 'Cancel', style: labelStyle);

    return SkeuKeyBox(
      variant: KeyVariant.secondary,
      radius: 8,
      height: 48,
      padding: const EdgeInsets.all(1),
      child: TextButton(
        onPressed: () {
          AppHaptics.tap();
          (onPressedCancel ?? () => Navigator.pop(context))();
        },
        style: TextButton.styleFrom(
          backgroundColor: AppColors.transparentColor,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: label,
      ),
    );
  }
}
