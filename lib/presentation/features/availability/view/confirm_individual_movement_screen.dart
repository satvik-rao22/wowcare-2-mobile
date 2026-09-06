import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';
import 'package:wowcare/presentation/features/availability/widgets/individual_movement_models.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';
import 'package:wowcare/presentation/features/staff/widgets/staff_form_layout.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

class ConfirmIndividualMovementScreen extends StatelessWidget {
  const ConfirmIndividualMovementScreen({super.key, required this.item});

  final MovementItem item;

  @override
  Widget build(BuildContext context) {
    final responsive = ResponsiveHelper(context);
    return StaffFormLayout(
      title: 'Confirm Individual Student Movement',
      bottomBar: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            responsive.horizontalSpacing,
            0,
            responsive.horizontalSpacing,
            12,
          ),
          child: Row(
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
                  label: 'Confirm',
                  onPressed: () => Navigator.of(context).pop(true),
                ),
              ),
            ],
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _infoRow('Student', item.name),
          const Divider(height: 18),
          _infoRow('Movement Type', item.movementTypeLabel),
          _infoRow('From', item.fromClassroom.isEmpty ? '-' : item.fromClassroom),
          _infoRow('To', item.toClassroom.isEmpty ? '-' : item.toClassroom),
          _infoRow('Movement Date', DateFormat('MMM dd, yyyy').format(item.movementDate)),
          _infoRow('Comment', item.comment.isEmpty ? '-' : item.comment),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.movementConfirmLabel,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.movementConfirmValue,
            ),
          ),
        ],
      ),
    );
  }
}
