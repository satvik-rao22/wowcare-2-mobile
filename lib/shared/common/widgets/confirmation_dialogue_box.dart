import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final String confirmText;
  final String cancelText;
  final bool showSkipButton;

  const ConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    this.confirmText = 'Yes',
    this.cancelText = 'No',
    this.showSkipButton = false,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppPalette.surfaceCard,
      title: Text(title),
      content: Text(content),
      actions: [
        if (showSkipButton) ...[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Skip action
            child: Text(
              cancelText,
              style: TextStyle(
                color: AppColors.primaryColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        TextButton(
          onPressed: () => Navigator.of(context).pop(true), // Confirm action
          child: SkeuKeyBox(
            variant: KeyVariant.primary,
            radius: 8,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              confirmText,
              style: const TextStyle(
                color: AppPalette.onBrand,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
