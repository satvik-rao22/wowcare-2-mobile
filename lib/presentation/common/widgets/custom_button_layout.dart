import 'package:flutter/material.dart';
// import 'package:wowcare/core/common/widgets/custom_cancel_button.dart';
// import 'package:wowcare/core/common/widgets/custom_confirm_button.dart';
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
              child: ElevatedButton(
                onPressed: onPressedCancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(cancelButtonLabel ?? 'Cancel'),
              ),
              // TODO: Re-enable when CustomCancelButton is available
              // child: CustomCancelButton(
              //   cancelButtonLabel: cancelButtonLabel,
              //   onPressedCancel: onPressedCancel,
              // ),
            ),
          if (showCancelButton) const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: onPressedConfirm,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.themeColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(confirmButtonLabel),
            ),
            // TODO: Re-enable when CustomConfirmButton is available
            // child: CustomConfirmButton(
            //   label: confirmButtonLabel,
            //   onPressed: onPressedConfirm,
            // ),
          ),
        ],
      ),
    );
  }
}