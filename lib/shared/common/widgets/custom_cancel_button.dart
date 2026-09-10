import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';

class CustomCancelButton extends StatelessWidget {
  const CustomCancelButton({
    this.cancelButtonLabel,
    this.onPressedCancel,
    this.gradientLabel = false,
    super.key,
  });

  final String? cancelButtonLabel;
  final void Function()? onPressedCancel;

  /// When true, the label text is painted with the primary gradient instead of
  /// the flat [AppColors.primaryColor].
  final bool gradientLabel;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(
      color: AppColors.primaryColor,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    );
    final label = Text(cancelButtonLabel ?? 'Cancel', style: labelStyle);

    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: AppColors.buildPrimaryGradient(), // gradient border
      ),
      padding: const EdgeInsets.all(1),
      child: TextButton(
        onPressed: onPressedCancel ?? () => Navigator.pop(context),
        style: TextButton.styleFrom(
          backgroundColor: AppColors.whiteColor,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: gradientLabel
            ? ShaderMask(
                blendMode: BlendMode.srcIn,
                shaderCallback: (bounds) =>
                    AppColors.buildPrimaryGradient().createShader(
                      Rect.fromLTWH(0, 0, bounds.width, bounds.height),
                    ),
                child: Text(
                  cancelButtonLabel ?? 'Cancel',
                  style: labelStyle.copyWith(color: AppColors.whiteColor),
                ),
              )
            : label,
      ),
    );
  }
}
