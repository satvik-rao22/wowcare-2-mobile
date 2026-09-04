import 'dart:async' show unawaited;

import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/widgets/dropdown_field.dart';
import 'package:wowcare/redesign/features/attendance/models/models.dart';

/// The Time field, the second and last field on both forms.
///
/// The value is a clock time rather than an instant: the API takes
/// `{hour, minute}` on the school's own clock, and the device's timezone
/// never comes into it.
class AttendanceTimeField extends StatelessWidget {
  const AttendanceTimeField({
    required this.label,
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  final String label;
  final ClockTime value;
  final ValueChanged<ClockTime> onChanged;
  final bool enabled;

  Future<void> _pick(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: value.hour, minute: value.minute),
      helpText: label,
    );
    if (picked != null) onChanged(ClockTime(picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) => DropdownField(
    label: label,
    value: value.label,
    leadingIcon: AppIcons.clock,
    enabled: enabled,
    onTap: () => unawaited(_pick(context)),
  );
}
