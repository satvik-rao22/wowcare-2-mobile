import 'package:flutter/material.dart';

import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

import 'scheduling_bottom_sheet_scaffold.dart';

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
    return SchedulingBottomSheetScaffold(
      children: [
        Text(
          "You are adding shift outside of this staff's availability. "
          'Please change the working schedule for this staff from '
          'their profile.',
          style: TextStyle(
            fontSize: SchedulingBottomSheetScaffold.titleFontSize(context),
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
            height: 1.35,
          ),
        ),
        SizedBox(height: context.isTablet ? 24 : 18),
        CustomButtonLayout(
          confirmButtonLabel: 'Ok',
          isForm: false,
          showCancelButton: false,
          onPressedConfirm: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
