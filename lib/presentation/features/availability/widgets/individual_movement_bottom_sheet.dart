import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/availability/model/individual_movement_models.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

enum IndividualMovementAction { edit, confirm, reject, moveToPending, delete }

/// API-aligned actions:
/// pending -> confirm/reject
/// rejected -> move to pending
/// confirmed -> no transition actions
Future<IndividualMovementAction?> showIndividualMovementOptionsBottomSheet(
  BuildContext context, {
  required MovementItem item,
  required MovementBucket currentBucket,
}) {
  final List<IndividualMovementAction> actions = <IndividualMovementAction>[];
  switch (currentBucket) {
    case MovementBucket.upcoming:
      actions.add(IndividualMovementAction.edit);
      actions.addAll(<IndividualMovementAction>[
        IndividualMovementAction.confirm,
        IndividualMovementAction.reject,
        IndividualMovementAction.delete,
      ]);
      break;
    case MovementBucket.overdue:
      actions.add(IndividualMovementAction.edit);
      actions.add(IndividualMovementAction.reject);
      actions.add(IndividualMovementAction.delete);
      break;
    case MovementBucket.confirmed:
      actions.add(IndividualMovementAction.edit);
      actions.add(IndividualMovementAction.reject);
      actions.add(IndividualMovementAction.delete);
      break;
    case MovementBucket.rejected:
      actions.add(IndividualMovementAction.edit);
      actions.add(IndividualMovementAction.delete);
      break;
  }

  return showModalBottomSheet<IndividualMovementAction>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.cardColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const SizedBox(height: 8),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppPalette.borderStrong,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 8, 4),
                child: Row(
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'More Options',
                        style: AppTextStyles.movementBottomSheetTitle,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.primaryColor.withValues(alpha: 0.7),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                child: Column(
                  children: actions
                      .map(
                        (IndividualMovementAction a) => _ActionTile(
                          action: a,
                          onTap: () => Navigator.pop(ctx, a),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

String _actionLabel(IndividualMovementAction a) {
  switch (a) {
    case IndividualMovementAction.edit:
      return 'Edit';
    case IndividualMovementAction.confirm:
      return 'Confirm';
    case IndividualMovementAction.reject:
      return 'Reject';
    case IndividualMovementAction.moveToPending:
      return 'Move to Pending';
    case IndividualMovementAction.delete:
      return 'Delete';
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.action, required this.onTap});

  final IndividualMovementAction action;
  final VoidCallback onTap;

  bool get _isDestructive => action == IndividualMovementAction.delete;

  IconData get _icon {
    switch (action) {
      case IndividualMovementAction.edit:
        return Icons.edit_outlined;
      case IndividualMovementAction.confirm:
        return Icons.check_circle_outline_rounded;
      case IndividualMovementAction.reject:
        return Icons.block_rounded;
      case IndividualMovementAction.moveToPending:
        return Icons.undo_rounded;
      case IndividualMovementAction.delete:
        return Icons.delete_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _isDestructive
        ? AppColors.errorColor
        : AppColors.primaryColor;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Row(
            children: <Widget>[
              Icon(_icon, size: 20, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _actionLabel(action),
                  style: AppTextStyles.movementActionTileLabel(color: color),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primaryColor.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
