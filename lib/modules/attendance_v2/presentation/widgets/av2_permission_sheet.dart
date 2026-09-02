import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';

/// Explains a missing permission and how to grant it. Returns `true` if the
/// user chose the primary action (e.g. open settings), `false`/`null` if they
/// cancelled.
Future<bool?> showAv2PermissionSheet(
  BuildContext context, {
  required String title,
  required String message,
  List<String> steps = const [],
  String confirmLabel = 'Open settings',
  IconData icon = Icons.folder_outlined,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Av2Colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius:
          BorderRadius.vertical(top: Radius.circular(Av2Spacing.radiusLg)),
    ),
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            Av2Spacing.md, Av2Spacing.sm, Av2Spacing.md, Av2Spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Av2Colors.border,
                  borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: Av2Spacing.md),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Av2Colors.surfaceMuted,
                    borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                  ),
                  child: Icon(icon, size: 20, color: Av2Colors.theme),
                ),
                const SizedBox(width: Av2Spacing.sm),
                Expanded(child: Text(title, style: Av2Text.title)),
              ],
            ),
            const SizedBox(height: Av2Spacing.sm),
            Text(message, style: Av2Text.body),
            if (steps.isNotEmpty) ...[
              const SizedBox(height: Av2Spacing.md),
              for (var i = 0; i < steps.length; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: Av2Spacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: Av2Colors.surfaceMuted,
                          shape: BoxShape.circle,
                        ),
                        child: Text('${i + 1}',
                            style: Av2Text.caption
                                .copyWith(color: Av2Colors.theme)),
                      ),
                      const SizedBox(width: Av2Spacing.sm),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(steps[i], style: Av2Text.body),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            const SizedBox(height: Av2Spacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext, false),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Av2Colors.borderStrong),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                      ),
                    ),
                    child: Text('Cancel',
                        style: Av2Text.bodyMedium
                            .copyWith(color: Av2Colors.textPrimary)),
                  ),
                ),
                const SizedBox(width: Av2Spacing.sm),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                    child: InkWell(
                      onTap: () => Navigator.pop(sheetContext, true),
                      borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
                      child: Ink(
                        height: 46,
                        decoration: BoxDecoration(
                          gradient: Av2Colors.primaryGradient,
                          borderRadius:
                              BorderRadius.circular(Av2Spacing.radiusSm),
                        ),
                        child: Center(
                          child: Text(confirmLabel,
                              style: Av2Text.bodyMedium
                                  .copyWith(color: Colors.white)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
