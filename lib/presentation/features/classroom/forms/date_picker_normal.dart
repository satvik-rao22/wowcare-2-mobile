import 'package:flutter/material.dart';
import 'package:wowcare/core/utils/app_time.dart';
import 'package:wowcare/shared/common/widgets/calendar_dialog.dart';

/// Normal (single) date picker used across the app.
///
/// This is intentionally implemented as a thin wrapper around the shared
/// [CalendarDialog] so feature modules can standardize on a single import:
/// `@lib/presentation/features/classroom/forms/date_picker_normal.dart`.
Future<DateTime?> pickNormalDate({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
}) async {
  final now = AppTime.now();
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => CalendarDialog(
      isRangePicker: false,
      isTimePicker: false,
      initialDate: initialDate ?? now,
      firstDate: firstDate,
      lastDate: lastDate,
      whiteBgColor: true,
    ),
  );

  final date = result?['date'];
  if (date is DateTime) {
    return DateTime(date.year, date.month, date.day);
  }
  return null;
}
