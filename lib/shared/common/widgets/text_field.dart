import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_inner_shadow.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final String? hintText;
  final String? Function(String?)? validator;

  /// Kept for source compatibility. Every field is a well now, so it is
  /// always filled: leaving one unfilled *and* edgeless would make it
  /// invisible.
  final bool isFilled;
  final bool isPassword;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  /// Optional callback for value changes.
  final ValueChanged<String>? onChanged;

  /// Kept for source compatibility. It never actually painted a gradient —
  /// see [_buildGradientTextStyle] — and now selects nothing different.
  final bool usePrimaryGradientText;

  /// Optional base font size for the input text.
  final double? textFontSize;

  /// Optional font weight for the input text.
  final FontWeight? textFontWeight;

  const CustomTextField({
    super.key,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.hintText,
    this.validator,
    this.isFilled = false,
    this.isPassword = false,
    this.readOnly = false,
    this.prefixIcon,
    this.suffixIcon,
    this.focusNode,
    this.nextFocusNode,
    this.onChanged,
    this.usePrimaryGradientText = false,
    this.textFontSize,
    this.textFontWeight,
  });

  @override
  Widget build(BuildContext context) {
    return SkeuFieldWell(
      radius: 8,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        focusNode: focusNode,
        readOnly: readOnly,
        obscureText: isPassword,
        validator: validator,
        onFieldSubmitted: nextFocusNode != null
            ? (_) => nextFocusNode!.requestFocus()
            : null,
        onChanged: (value) {
          if (onChanged != null) {
            onChanged!(value);
          }
        },
        style: usePrimaryGradientText ? _buildGradientTextStyle() : null,
        decoration: AppSurfaces.fieldDecoration(radius: 8).copyWith(
          hintText: hintText,
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppSurfaces.fieldFill,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  TextStyle _buildGradientTextStyle() {
    final baseSize = textFontSize ?? 14.0;
    final baseWeight = textFontWeight ?? FontWeight.w500;

    // NOTE: a shader via `foreground: Paint()..shader` breaks caret
    // placement on editable fields (you can't tap to position the cursor —
    // it jumps to the end), which is why this was always a solid colour.
    return TextStyle(
      fontFamily: AppFonts.body,
      fontSize: baseSize,
      fontWeight: baseWeight,
      color: AppColors.primaryColor,
    );
  }
}
