import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/widgets/dropdown_field.dart';
import 'package:wowcare/redesign/features/students/students_formats.dart';
import 'package:wowcare/redesign/features/students/students_strings.dart';

/// A well that opens the platform date picker (5d, 5e, 5f).
///
/// Core's `DropdownField` is the well and the caret; this pairs it with the
/// picker and with the one way M05 writes a date, so a birth date and a
/// document's expiry never read differently.
class DateField extends StatelessWidget {
  const DateField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.isRequired = false,
    this.helpText,
    this.errorText,
    this.firstDate,
    this.lastDate,
    super.key,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final bool isRequired;
  final String? helpText;
  final String? errorText;

  /// Defaults to twenty years either side of now, which covers a birth date
  /// and a document that expires.
  final DateTime? firstDate;
  final DateTime? lastDate;

  static const int _yearsEitherSide = 20;

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: value ?? now,
      firstDate: firstDate ?? DateTime(now.year - _yearsEitherSide),
      lastDate: lastDate ?? DateTime(now.year + _yearsEitherSide),
      helpText: label,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => DropdownField(
    label: label,
    isRequired: isRequired,
    value: value == null ? null : StudentsFormats.date(value!),
    placeholder: StudentsStrings.pickDate,
    helpText: helpText,
    errorText: errorText,
    leadingIcon: AppIcons.calendar,
    onTap: () => unawaited(_pick(context)),
  );
}
