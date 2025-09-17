import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/core/res/colors.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.label,
    this.hintText,
    this.isTextArea = false,
    this.isNumeric = false, // Add numeric input flag
    this.controller,
    this.onChanged,
    this.maxLength,
    this.allowDecimal = false, // Allow decimal numbers by default
  });

  final String? label;
  final String? hintText;
  final bool isTextArea;
  final bool isNumeric; // Control whether this is a numeric field
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int? maxLength; // Optional maximum length for input
  final bool allowDecimal; // Control whether to allow decimal points in numeric mode

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.5),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        if (label != null) const SizedBox(height: 12),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLength: maxLength,
          // Configure appropriate keyboard based on field type
          keyboardType: _getKeyboardType(),
          // Apply input formatters for numeric restrictions if needed
          inputFormatters: _getInputFormatters(),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.primaryColor.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.primaryColor.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: AppColors.primaryColor.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 8,
              horizontal: 12,
            ),
            hintText: hintText,
            hintStyle: TextStyle(
              color: AppColors.primaryColor.withValues(alpha: 0.5),
              fontSize: 15,
            ),
            // Only show counter if maxLength is specified
            counterText: maxLength != null ? '' : null,
          ),
          maxLines: isTextArea ? 5 : 1,
        ),
      ],
    );
  }

  // Helper method to determine keyboard type based on field properties
  TextInputType _getKeyboardType() {
    if (isNumeric) {
      return allowDecimal 
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.number;
    } else if (isTextArea) {
      return TextInputType.multiline;
    } else {
      return TextInputType.text;
    }
  }

  // Helper method to get input formatters based on field type
  List<TextInputFormatter>? _getInputFormatters() {
    if (!isNumeric) return null;
    
    if (allowDecimal) {
      // Allow digits and at most one decimal point
      return [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
      ];
    } else {
      // Allow only digits
      return [
        FilteringTextInputFormatter.digitsOnly,
      ];
    }
  }
}
