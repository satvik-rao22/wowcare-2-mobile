import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

class CustomTextField extends StatelessWidget {
  const CustomTextField({
    super.key,
    this.label,
    this.hintText,
    this.isTextArea = false,
    this.isNumeric = false, // Add numeric input flag
    this.controller,
    this.onChanged,
    this.maxLength, // Optional maximum length for input
    this.allowDecimal = false, // Allow decimal numbers by default
  });

  final String? label;
  final String? hintText;
  final bool isTextArea;
  final bool isNumeric; // Control whether this is a numeric field
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final int? maxLength; // Optional maximum length for input
  final bool
  allowDecimal; // Control whether to allow decimal points in numeric mode

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(
            label!,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppPalette.textSecondary,
            ),
          ),
        if (label != null) const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          maxLength: maxLength,
          maxLines: isTextArea ? 4 : 1,
          keyboardType: isNumeric
              ? (allowDecimal
                    ? const TextInputType.numberWithOptions(decimal: true)
                    : TextInputType.number)
              : TextInputType.text,
          inputFormatters: isNumeric
              ? [
                  if (!allowDecimal)
                    FilteringTextInputFormatter.digitsOnly
                  else
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ]
              : null,
          decoration: AppSurfaces.fieldDecoration(radius: 8).copyWith(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: AppPalette.textMuted,
              fontSize: 14,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            counterText: '', // Hide character counter
          ),
        ),
      ],
    );
  }
}
