import 'package:flutter/services.dart';

class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final newText = newValue.text;

    if (newText.isEmpty) {
      return newValue;
    }

    // Extract only digits from the new text
    final digitsOnly = newText.replaceAll(RegExp(r'\D'), '');
    final charCount = digitsOnly.length;

    // Build the formatted text from the digits
    String formattedText;
    if (charCount == 0) {
      formattedText = '';
    } else if (charCount <= 3) {
      formattedText = '($digitsOnly';
    } else if (charCount <= 6) {
      formattedText =
          '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3)}';
    } else {
      formattedText =
          '(${digitsOnly.substring(0, 3)}) ${digitsOnly.substring(3, 6)}-${digitsOnly.substring(6)}';
    }

    // Preserve the caret position by:
    // 1. Counting how many digits are before the current caret.
    // 2. Placing the caret after the same number of digits in the formatted text.
    final oldSelectionIndex = newValue.selection.extentOffset.clamp(
      0,
      newText.length,
    );
    final substringBeforeCaret = newText.substring(0, oldSelectionIndex);
    final digitsBeforeCaret = substringBeforeCaret
        .replaceAll(RegExp(r'\D'), '')
        .length;

    int caretIndex = 0;
    int digitCount = 0;
    while (caretIndex < formattedText.length &&
        digitCount < digitsBeforeCaret) {
      if (RegExp(r'\d').hasMatch(formattedText[caretIndex])) {
        digitCount++;
      }
      caretIndex++;
    }

    caretIndex = caretIndex.clamp(0, formattedText.length);

    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: caretIndex),
    );
  }
}

class NameCapitalizationFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String original = newValue.text;

    // Normalize spaces: collapse multiple and remove trailing spaces
    String text = original;
    text = text.replaceFirst(RegExp(r"\s+"), ' '); // collapse first occurrence
    text = text.replaceAll(RegExp(r"\s{2,}"), ' ');
    text = text.replaceAll(RegExp(r"\s+\z"), '');

    if (text.isEmpty) {
      return newValue.copyWith(
        text: text,
        selection: const TextSelection.collapsed(offset: 0),
      );
    }

    // Enforce first letter uppercase, remaining lowercase
    final firstChar = text[0].toUpperCase();
    final rest = text.length > 1 ? text.substring(1).toLowerCase() : '';
    final formatted = firstChar + rest;

    // Try to preserve caret position relative to the transformation
    final oldOffset = newValue.selection.extentOffset;
    final lengthDelta = formatted.length - original.length;
    final newOffset = (oldOffset + lengthDelta).clamp(0, formatted.length);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}

class TrimFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final original = newValue.text;
    final trimmed = original.trimLeft();

    // Number of leading characters removed
    final leadingRemoved = original.length - trimmed.length;

    // Adjust caret to account for removed leading spaces
    final oldOffset = newValue.selection.extentOffset;
    final newOffset = (oldOffset - leadingRemoved).clamp(0, trimmed.length);

    return TextEditingValue(
      text: trimmed,
      selection: TextSelection.collapsed(offset: newOffset),
    );
  }
}
