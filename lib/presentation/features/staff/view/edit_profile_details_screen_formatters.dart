import 'package:flutter/services.dart';

/// Simple phone formatter to display US numbers as (XXX) XXX-XXXX
/// while keeping only digits for API submission.
class EditPhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length && i < 10; i++) {
      if (i == 0) buffer.write('(');
      if (i == 3) buffer.write(') ');
      if (i == 6) buffer.write('-');
      buffer.write(digitsOnly[i]);
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// Formats US ZIP codes as either:
/// - 12345
/// - 12345-6789
/// while keeping only digits for validation/API submission.
class ZipCodeFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digitsOnly = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) {
      return const TextEditingValue(text: '');
    }

    final buffer = StringBuffer();
    for (var i = 0; i < digitsOnly.length && i < 9; i++) {
      if (i == 5) buffer.write('-');
      buffer.write(digitsOnly[i]);
    }
    final formatted = buffer.toString();

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

String formatUsZipForDisplay(String raw) {
  final digits = raw.replaceAll(RegExp(r'\D'), '');
  if (digits.isEmpty) return '';
  if (digits.length <= 5) return digits.substring(0, digits.length);
  final first5 = digits.substring(0, 5);
  final last4 = digits.substring(5, digits.length.clamp(5, 9));
  return last4.isEmpty ? first5 : '$first5-$last4';
}
