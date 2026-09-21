import 'package:flutter/material.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';

/// Actions available on an attendance/absence record.
enum Av2RecordAction { edit, delete }

/// Shows a bottom sheet offering Edit / Delete and returns the chosen action
/// (or null if dismissed). Reused for both session rows and absence rows.
Future<Av2RecordAction?> showAv2ActionSheet(
  BuildContext context, {
  String title = 'Edit record',
}) {
  return showModalBottomSheet<Av2RecordAction>(
    context: context,
    backgroundColor: Av2Colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(Av2Spacing.radiusLg)),
    ),
    builder: (context) => _Av2ActionSheet(title: title),
  );
}

class _Av2ActionSheet extends StatelessWidget {
  const _Av2ActionSheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: Av2Spacing.sm),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Av2Colors.border,
              borderRadius: BorderRadius.circular(Av2Spacing.radiusPill),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                Av2Spacing.md, Av2Spacing.md, Av2Spacing.md, Av2Spacing.xs),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, style: Av2Text.title),
            ),
          ),
          _ActionItem(
            icon: Icons.edit_outlined,
            label: 'Edit',
            color: Av2Colors.textPrimary,
            onTap: () => Navigator.pop(context, Av2RecordAction.edit),
          ),
          _ActionItem(
            icon: Icons.delete_outline,
            label: 'Delete',
            color: Av2Colors.danger,
            onTap: () => Navigator.pop(context, Av2RecordAction.delete),
          ),
          const SizedBox(height: Av2Spacing.sm),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  const _ActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: Av2Spacing.md, vertical: Av2Spacing.sm),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: Av2Spacing.sm),
            Text(label, style: Av2Text.body.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}
