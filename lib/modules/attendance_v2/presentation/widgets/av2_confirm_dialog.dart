import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';

/// A small destructive-confirmation dialog. Returns true if confirmed.
///
/// Uses a plain [AlertDialog] so the face, corners and title type all come
/// from `ThemeData.dialogTheme`, and marks the destructive action with
/// [AppColors.errorColor] — the same shape the rest of the app uses for a
/// delete confirmation (see `showDeleteHolidayConfirmation`).
Future<bool> showAv2ConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(cancelLabel),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          style: TextButton.styleFrom(foregroundColor: AppColors.errorColor),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}
