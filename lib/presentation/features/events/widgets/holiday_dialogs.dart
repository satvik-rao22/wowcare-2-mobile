import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/domain/features/events/entities/holiday.dart';
import 'package:wowcare/core/theme/app_haptics.dart';

/// Confirmation dialog shown before deleting a school holiday.
///
/// Returns `true` only when the admin explicitly taps **Delete**; tapping
/// **Cancel** or dismissing the dialog (barrier tap / back) returns `false`.
/// The holiday name is rendered with a hard line cap so an over-long name
/// (e.g. from bad server data) can't blow out the dialog height.
Future<bool> showDeleteHolidayConfirmation(
  BuildContext context,
  Holiday holiday,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Delete holiday?'),
      content: Text(
        '"${holiday.name}" will be removed.',
        maxLines: 4,
        overflow: TextOverflow.ellipsis,
      ),
      actions: [
        TextButton(
          onPressed: () {
            AppHaptics.tap();
            Navigator.pop(dialogContext, false);
          },
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            AppHaptics.tap();
            Navigator.pop(dialogContext, true);
          },
          style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
