import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/custom_cancel_button.dart';
import 'package:wowcare/shared/common/widgets/custom_confirm_button.dart';
import 'package:wowcare/app/theme/colors.dart';

class CustomButtonLayout extends StatelessWidget {
  const CustomButtonLayout({
    required this.confirmButtonLabel,
    required this.onPressedConfirm,
    this.cancelButtonLabel,
    this.onPressedCancel,
    this.showCancelButton = true,
    this.isForm = true,
    super.key,
  });

  final String confirmButtonLabel;
  final String? cancelButtonLabel;
  final void Function()? onPressedConfirm;
  final void Function()? onPressedCancel;
  final bool showCancelButton;
  final bool isForm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: isForm
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: AppColors.cardColor,
            )
          : null,
      padding: isForm ? const EdgeInsets.all(20) : null,
      child: Row(
        children: [
          if (showCancelButton)
            Expanded(
              child: CustomCancelButton(
                cancelButtonLabel: cancelButtonLabel,
                onPressedCancel: onPressedCancel,
              ),
            ),
          if (showCancelButton) const SizedBox(width: 16),
          Expanded(
            child: CustomConfirmButton(
              label: confirmButtonLabel,
              onPressed: onPressedConfirm,
            ),
          ),
        ],
      ),
    );
  }
}