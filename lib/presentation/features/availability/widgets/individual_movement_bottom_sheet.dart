import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';

enum IndividualMovementAction { edit, confirm, reject, moveToPending, delete }

/// API-aligned actions:
/// pending -> confirm/reject
/// rejected -> move to pending
/// confirmed -> no transition actions
Future<IndividualMovementAction?> showIndividualMovementOptionsBottomSheet(
  BuildContext context, {
  required MovementItem item,
}) {
  final List<IndividualMovementAction> actions = <IndividualMovementAction>[];
  switch (item.workflowStatus) {
    case MovementWorkflowStatus.pending:
      actions.add(IndividualMovementAction.edit);
      actions.addAll(<IndividualMovementAction>[
        IndividualMovementAction.confirm,
        IndividualMovementAction.reject,
      ]);
      break;
    case MovementWorkflowStatus.confirmed:
      return Future<IndividualMovementAction?>.value(null);
    case MovementWorkflowStatus.rejected:
      actions.add(IndividualMovementAction.edit);
      actions.add(IndividualMovementAction.moveToPending);
      actions.add(IndividualMovementAction.delete);
      break;
  }

  return showModalBottomSheet<IndividualMovementAction>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(0, 8, 0, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                dense: true,
                title: const Text(
                  'More Options',
                  style: TextStyle(
                    fontFamily: Fonts.manrope,
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ),
                trailing: IconButton(
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close, color: Colors.grey),
                ),
              ),
              const Divider(height: 1),
              ...actions.map(
                (IndividualMovementAction a) => _ActionTile(
                  title: _actionLabel(a),
                  onTap: () => Navigator.pop(ctx, a),
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
  const _ActionTile({
    required this.title,
    required this.onTap,
  });

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      title: Text(
        title,
        style: const TextStyle(
          fontFamily: Fonts.manrope,
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: AppColors.primaryColor,
        ),
      ),
      onTap: onTap,
    );
  }
}
