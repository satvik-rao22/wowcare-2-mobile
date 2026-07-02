import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';

/// Confirmation dialog for deactivation flows (PRD FR-DM-14, FR-SD-11,
/// FR-MS-10). Accessible by default: Material's [AlertDialog] sets
/// `role=dialog`/modal semantics, traps focus, and closes on Escape.
class AssessmentConfirmDialog extends StatelessWidget {
  const AssessmentConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    this.confirmLabel = 'Deactivate',
    this.destructive = true,
  });

  final String title;
  final String message;
  final String confirmLabel;
  final bool destructive;

  /// Returns true when confirmed, false/null when cancelled.
  static Future<bool> show(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Deactivate',
    bool destructive = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AssessmentConfirmDialog(
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        destructive: destructive,
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor:
                destructive ? AppColors.errorColor : AssessmentUi.accent,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
