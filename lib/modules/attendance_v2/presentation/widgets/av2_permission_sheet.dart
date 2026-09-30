import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';
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
    // Ground and corners come from ThemeData.bottomSheetTheme.
    builder: (sheetContext) => SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Av2Spacing.md,
          Av2Spacing.sm,
          Av2Spacing.md,
          Av2Spacing.md,
        ),
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
                  decoration: AppSurfaces.well(radius: Av2Spacing.radiusSm),
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
                        // 11 = half of 22: a well cut to a circle.
                        decoration: AppSurfaces.well(radius: 11),
                        child: Text(
                          '${i + 1}',
                          style: Av2Text.caption.copyWith(
                            color: Av2Colors.theme,
                          ),
                        ),
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
            CustomButtonLayout(
              isForm: false,
              confirmButtonLabel: confirmLabel,
              onPressedConfirm: () => Navigator.pop(sheetContext, true),
              onPressedCancel: () => Navigator.pop(sheetContext, false),
            ),
          ],
        ),
      ),
    ),
  );
}
