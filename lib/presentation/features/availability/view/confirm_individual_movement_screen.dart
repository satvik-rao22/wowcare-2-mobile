import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/fonts.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

class ConfirmIndividualMovementScreen extends StatelessWidget {
  const ConfirmIndividualMovementScreen({super.key, required this.item});

  final MovementItem item;

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Confirm Individual Student Movement',
            style: TextStyle(
              fontFamily: Fonts.manrope,
              fontSize: 22,
              fontWeight: FontWeight.w500,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primaryColor.withValues(alpha: 0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _infoRow('Student', item.name),
                  _infoRow('Current Classroom', item.fromClassroom),
                  _infoRow('Next to Classroom', item.toClassroom),
                  _infoRow('Movement Date', DateFormat('MMM dd, yyyy').format(item.movementDate)),
                  _infoRow('Comment', item.comment.isEmpty ? '-' : item.comment),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              Expanded(
                child: CustomCancelButton(
                  cancelButtonLabel: 'Back',
                  onPressedCancel: () => Navigator.of(context).pop(false),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomConfirmButton(
                  label: 'Save',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: Fonts.manrope,
                fontSize: 13,
                color: AppColors.primaryColor.withValues(alpha: 0.55),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: Fonts.manrope,
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
