import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';

enum IndividualMovementAction { edit, confirm, reject }

Future<IndividualMovementAction?> showIndividualMovementOptionsBottomSheet(
  BuildContext context,
) {
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
              _ActionTile(
                title: 'Edit',
                onTap: () => Navigator.pop(ctx, IndividualMovementAction.edit),
              ),
              _ActionTile(
                title: 'Confirm',
                onTap: () => Navigator.pop(ctx, IndividualMovementAction.confirm),
              ),
              _ActionTile(
                title: 'Reject',
                onTap: () => Navigator.pop(ctx, IndividualMovementAction.reject),
              ),
            ],
          ),
        ),
      );
    },
  );
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
