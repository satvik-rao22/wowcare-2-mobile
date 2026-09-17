import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// Shared bottom-sheet picker for a task's status / priority, used by both the
/// list/board cards and the detail screen so inline editing behaves
/// identically everywhere. Returns the chosen option, or null if dismissed.
Future<T?> showTaskOptionPicker<T>({
  required BuildContext context,
  required String title,
  required List<T> options,
  required T current,
  required Color Function(T) colorOf,
  required IconData Function(T) iconOf,
  required String Function(T) labelOf,
}) {
  return showModalBottomSheet<T>(
    context: context,
    backgroundColor: AppPalette.surfaceCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Container(
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: AppPalette.borderStrong,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
          for (final option in options)
            ListTile(
              leading: Icon(iconOf(option), color: colorOf(option)),
              title: Text(labelOf(option), style: const TextStyle(fontSize: 14)),
              trailing: option == current
                  ? const Icon(Icons.check, color: AppColors.themeColor)
                  : null,
              onTap: () => Navigator.pop(sheetContext, option),
            ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
