import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

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
    return SkeuKeyBox(
      variant: KeyVariant.primary,
      radius: borderRadius?.topLeft.x ?? 10,
      width: width ?? 50,
      height: height ?? 50,
      child: FloatingActionButton(
        heroTag: null,
        onPressed: onPressed,
        backgroundColor: AppColors.transparentColor,
        elevation: 0,
        child: Text(label, style: textStyle),
      ),
    );
  }

  Widget _buildOutlinedButton() {
    return SkeuKeyBox(
      variant: KeyVariant.secondary,
      radius: borderRadius?.topLeft.x ?? 10,
      width: width ?? 50,
      height: height ?? 50,
      padding: const EdgeInsets.all(1),
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: AppColors.transparentColor,
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius ?? BorderRadius.circular(10),
          ),
        ),
        child: Text(
          label,
          style: (textStyle ?? const TextStyle()).copyWith(
            color: AppSurfaces.keyInk(KeyVariant.secondary),
          ),
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
