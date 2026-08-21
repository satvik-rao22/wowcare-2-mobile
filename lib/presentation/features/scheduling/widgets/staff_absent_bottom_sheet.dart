import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

/// Informational sheet shown when a single-day shift is being added on a date
/// the staff is marked absent. Hard-blocks the create (single OK button).
class StaffAbsentBottomSheet extends StatelessWidget {
  const StaffAbsentBottomSheet({super.key, required this.message});

  final String message;

  static Future<void> show(BuildContext context, DateTime absentDate) {
    final formatted = DateFormat('EEE, MMM d, yyyy').format(absentDate);
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.transparent,
      builder: (_) => StaffAbsentBottomSheet(
        message: 'This staff is marked absent for $formatted.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth > 600;
    final isLargeTablet = screenWidth > 900;
    final bottomSafe = MediaQuery.of(context).padding.bottom;

    final horizontalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 16.0);
    final verticalPadding = isLargeTablet ? 32.0 : (isTablet ? 24.0 : 20.0);
    final titleFontSize = isLargeTablet ? 18.0 : (isTablet ? 16.0 : 15.0);
    final borderRadius = isLargeTablet ? 24.0 : (isTablet ? 20.0 : 16.0);

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: isLargeTablet ? 1200.0 : double.infinity,
        ),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: horizontalPadding,
            right: horizontalPadding,
            top: verticalPadding,
            bottom: verticalPadding + bottomSafe,
          ),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(borderRadius),
              topRight: Radius.circular(borderRadius),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                message,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryColor,
                  height: 1.35,
                ),
              ),
              SizedBox(height: isTablet ? 24 : 18),
              CustomButtonLayout(
                confirmButtonLabel: 'Ok',
                isForm: false,
                showCancelButton: false,
                onPressedConfirm: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
