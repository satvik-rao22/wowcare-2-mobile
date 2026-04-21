import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class CustomTextField extends StatelessWidget {
  final TextEditingController? controller;
  final TextInputType keyboardType;
  final Color? fillColor;
  final String? hintText;
  final String? Function(String?)? validator;
  final bool isFilled;
  final bool isPassword;
  final bool readOnly;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final FocusNode? focusNode;
  final FocusNode? nextFocusNode;

  /// Optional callback for value changes.
  final ValueChanged<String>? onChanged;

  /// When true, uses primary gradient for entered text (like sign-in / forgot password).
  final bool usePrimaryGradientText;

  /// Optional base font size for the input text.
  final double? textFontSize;

  /// Optional font weight for the input text.
  final FontWeight? textFontWeight;

  const CustomTextField({
    super.key,
    this.controller,
    this.keyboardType = TextInputType.text,
    this.fillColor,
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
    return TextFormField(
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
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        filled: isFilled,
        fillColor: fillColor ?? Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.themeColor),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  TextStyle _buildGradientTextStyle() {
    final baseSize = textFontSize ?? 14.0;
    final baseWeight = textFontWeight ?? FontWeight.w500;
    final isEmpty = (controller?.text.isEmpty ?? true);

    if (isEmpty) {
      return TextStyle(
        fontFamily: 'Manrope',
        fontSize: baseSize,
        fontWeight: baseWeight,
        color: const Color(0xFF333333),
      );
    }

    return TextStyle(
      fontFamily: 'Manrope',
      fontSize: baseSize,
      fontWeight: baseWeight,
      foreground: Paint()
        ..shader = AppColors.buildPrimaryGradient().createShader(
          const Rect.fromLTWH(0, 0, 200, 20),
        ),
    );
  }
}
