import 'package:flutter/services.dart';

/// Formats US phone numbers as (XXX) XXX-XXXX as the user types, keeping
/// only the first 10 digits (extra digits from a paste are dropped rather
/// than appended past the mask).
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }

    String formattedText;
    if (digits.length <= 3) {
      formattedText = '($digits';
    } else if (digits.length <= 6) {
      formattedText = '(${digits.substring(0, 3)}) ${digits.substring(3)}';
    } else {
      final d = digits.substring(0, digits.length.clamp(0, 10));
      formattedText =
          '(${d.substring(0, 3)}) ${d.substring(3, 6)}-${d.substring(6)}';
    }

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: formattedText.length),
    );
  }
}

/// Normalizes free-text name input: collapses internal whitespace runs,
/// trims trailing whitespace, and enforces "First letter uppercase, rest
/// lowercase" casing.
class NameCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Remove trailing spaces
    text = text.replaceFirst(
      RegExp(r"\s+"),
      ' ',
    ); // collapse multiple spaces inside
    text = text.replaceAll(RegExp(r"\s{2,}"), ' ');
    text = text.replaceAll(RegExp(r"\s+\z"), '');

    if (text.isEmpty) {
      return newValue.copyWith(
        text: text,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    final firstChar = text[0].toUpperCase();
    final rest = text.length > 1 ? text.substring(1).toLowerCase() : '';
    final formatted = firstChar + rest;

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Strips leading whitespace as the user types (trailing whitespace is left
/// alone so a space between words isn't fought while typing).
class TrimFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final original = newValue.text;
    final trimmed = original.trimLeft();

    // Preserve caret at end for simplicity
    final leadingRemoved = original.length - trimmed.length;
    final oldOffset = newValue.selection.extentOffset;
    final newOffset = (oldOffset - leadingRemoved).clamp(0, trimmed.length);

    return TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
