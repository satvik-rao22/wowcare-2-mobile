import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class CustomFloatingTextButton extends StatelessWidget {
  const CustomFloatingTextButton({
    required this.onPressed,
    required this.label,
    this.textStyle,
    this.borderRadius,
    this.height,
    this.width,
    this.isFilled = true,
    super.key,
  });

  final void Function()? onPressed;
  final String label;
  final TextStyle? textStyle;
  final BorderRadius? borderRadius;
  final double? height;
  final double? width;
  final bool? isFilled;

  Widget _buildFilledButton() {
    return Container(
      height: height ?? 50,
      width: width ?? 50,
      decoration: BoxDecoration(
        shape: BoxShape.rectangle,
        borderRadius: borderRadius ?? BorderRadius.circular(10),
        gradient: AppColors.buildPrimaryGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: FloatingActionButton(
        heroTag: null,
        onPressed: onPressed,
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Text(label, style: textStyle),
      ),
    );
  }

  Widget _buildOutlinedButton() {
    return Container(
      height: height ?? 50,
      width: width ?? 50,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(10),
        gradient: AppColors.buildSecondaryGradient(),
      ),
      padding: const EdgeInsets.all(1),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(10),
          ),
        ),
        child: ShaderMask(
          shaderCallback: (Rect bounds) =>
              AppColors.buildSecondaryGradient().createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(label, style: textStyle),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isFilled == false) {
      return _buildOutlinedButton();
    }
    return _buildFilledButton();
  }
}
