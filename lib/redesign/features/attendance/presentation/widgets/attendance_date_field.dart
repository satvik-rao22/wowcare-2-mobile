import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/widgets/dropdown_field.dart';
import 'package:wowcare/redesign/features/attendance/attendance_formats.dart';

/// The Date field, on both forms and in the day sheet.
///
/// Core's `DropdownField` is the well and the caret; this pairs it with the
/// platform picker and with the one way M04 writes a date.
class AttendanceDateField extends StatelessWidget {
  const AttendanceDateField({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.today,
    this.enabled = true,
    super.key,
  });

  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  /// The school's own day, which is as far forward as attendance goes.
  final DateTime today;
  final bool enabled;

  /// Attendance goes back to enrollment, which the demo world treats as a
  /// year. Forward it stops at today: tomorrow has no attendance.
  static const int _yearsBack = 1;

  Future<void> _pick(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: value,
      firstDate: DateTime(today.year - _yearsBack, today.month, today.day),
      lastDate: today,
      helpText: label,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) => DropdownField(
    label: label,
    value: AttendanceFormats.weekdayDate(value),
    leadingIcon: AppIcons.calendar,
    enabled: enabled,
    onTap: () => unawaited(_pick(context)),
  );
}
