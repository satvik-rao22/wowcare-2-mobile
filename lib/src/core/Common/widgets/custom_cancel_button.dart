import 'package:flutter/material.dart';
import '../../res/colors.dart';

class CustomCancelButton extends StatelessWidget {
  const CustomCancelButton({
    this.cancelButtonLabel,
    this.onPressedCancel,
    super.key,
  });

  final String? cancelButtonLabel;
  final void Function()? onPressedCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: AppColors.buildSecondaryGradient(),
      ),
      padding: const EdgeInsets.all(1),
      child: TextButton(
        onPressed: onPressedCancel ?? () => Navigator.pop(context),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: ShaderMask(
          shaderCallback: (Rect bounds) =>
              AppColors.buildSecondaryGradient().createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            cancelButtonLabel ?? 'Cancel',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 16 * (-3 / 100),
            ),
          ),
        ),
      ),
    );
  }
}
