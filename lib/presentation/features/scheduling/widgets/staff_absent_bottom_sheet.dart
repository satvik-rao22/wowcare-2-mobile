import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:wowcare/core/responsive/responsive_scope.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

import 'scheduling_bottom_sheet_scaffold.dart';

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
      backgroundColor: Colors.transparent,
      builder: (_) => StaffAbsentBottomSheet(
        message: 'This staff is marked absent for $formatted.',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SchedulingBottomSheetScaffold(
      children: [
        Text(
          message,
          style: TextStyle(
            fontSize: SchedulingBottomSheetScaffold.titleFontSize(context),
            fontWeight: FontWeight.w600,
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
