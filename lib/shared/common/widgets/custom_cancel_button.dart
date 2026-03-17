import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class CustomCancelButton extends StatelessWidget {
  const CustomCancelButton({
    this.cancelButtonLabel,
    this.onPressedCancel,
    super.key,
  });

  final String? cancelButtonLabel;
  final void Function()? onPressedCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: AppColors.buildPrimaryGradient(), // gradient border
      ),
      padding: const EdgeInsets.all(1),
      child: TextButton(
        onPressed: onPressedCancel ?? () => Navigator.pop(context),
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(
          cancelButtonLabel ?? 'Cancel',
          style: const TextStyle(
            color: AppColors.primaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}