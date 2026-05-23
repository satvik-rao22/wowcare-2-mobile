import 'package:flutter/material.dart';

import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

/// Hard-block notice shown when a recurring shift is being created on a day
/// the selected staff has no work-schedule entry for. Single OK button — there
/// is no override; the user must fix the staff's profile first.
class StaffNoAvailabilityBottomSheet extends StatelessWidget {
  const StaffNoAvailabilityBottomSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const StaffNoAvailabilityBottomSheet(),
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
            color: Colors.white,
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
                "You are adding shift outside of this staff's availability. "
                'Please change the working schedule for this staff from '
                'their profile.',
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
