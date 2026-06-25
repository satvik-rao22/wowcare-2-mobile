import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';

/// A small destructive-confirmation dialog. Returns true if confirmed.
Future<bool> showAv2ConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  String cancelLabel = 'Cancel',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => Dialog(
      backgroundColor: Av2Colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(Av2Spacing.radiusLg),
      ),
      child: Padding(
        padding: const EdgeInsets.all(Av2Spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Av2Text.title),
            const SizedBox(height: Av2Spacing.xs),
            Text(message, style: Av2Text.body.copyWith(color: Av2Colors.textSecondary)),
            const SizedBox(height: Av2Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Av2Colors.borderStrong),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                      ),
                    ),
                    child: Text(cancelLabel,
                        style: Av2Text.bodyMedium
                            .copyWith(color: Av2Colors.textPrimary)),
                  ),
                ),
                const SizedBox(width: Av2Spacing.sm),
                Expanded(
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: FilledButton.styleFrom(
                      backgroundColor: Av2Colors.danger,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                      ),
                    ),
                    child: Text(confirmLabel,
                        style: Av2Text.bodyMedium.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
