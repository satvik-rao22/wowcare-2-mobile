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

  /// When true, the field is drawn with a gradient (primary) border.
  final bool useGradientBorder;

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
    this.useGradientBorder = false,
  });

  @override
  Widget build(BuildContext context) {
    final field = TextFormField(
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
        filled: useGradientBorder ? true : isFilled,
        fillColor: useGradientBorder
            ? (fillColor ?? Colors.white)
            : (fillColor ?? Colors.grey.shade100),
        border: _border(useGradientBorder ? null : Colors.grey.shade300),
        enabledBorder: _border(useGradientBorder ? null : Colors.grey.shade300),
        focusedBorder:
            _border(useGradientBorder ? null : AppColors.themeColor),
        errorBorder: _border(useGradientBorder ? null : Colors.red),
        focusedErrorBorder: _border(useGradientBorder ? null : Colors.red),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );

    if (!useGradientBorder) return field;

    // Gradient border: an outer gradient container with a 1.5px inset reveals
    // the gradient as the field's border.
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.buildPrimaryGradient(),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(1.5),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(7),
        child: field,
      ),
    );
  }

  OutlineInputBorder _border(Color? color) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: color == null
            ? BorderSide.none
            : BorderSide(color: color),
      );

  TextStyle _buildGradientTextStyle() {
    final baseSize = textFontSize ?? 14.0;
    final baseWeight = textFontWeight ?? FontWeight.w500;

    // NOTE: A gradient via `foreground: Paint()..shader` breaks caret
    // placement on editable fields (you can't tap to position the cursor —
    // it jumps to the end). Use a solid themed color instead.
    return TextStyle(
      fontFamily: 'Manrope',
      fontSize: baseSize,
      fontWeight: baseWeight,
      color: AppColors.primaryColor,
    );
  }
}
