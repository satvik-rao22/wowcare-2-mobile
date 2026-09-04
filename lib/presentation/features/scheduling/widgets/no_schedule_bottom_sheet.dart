import 'package:flutter/material.dart';

import 'package:wowcare/core/responsive/responsive_ext.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

import 'scheduling_bottom_sheet_scaffold.dart';

/// Confirmation sheet shown when the user tries to add a shift on a day the
/// selected staff has no work schedule defined for. Tapping Yes signals that
/// the request should be sent with `forceAdd: true`.
class NoScheduleBottomSheet extends StatelessWidget {
  const NoScheduleBottomSheet({
    super.key,
    this.title = 'This staff has no schedule defined for the selected day. '
        'Do you still want to add this shift?',
  });

  final String title;

  /// Shows the sheet and returns `true` if the user taps Yes, `false`
  /// (or sheet dismiss) otherwise.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NoScheduleBottomSheet(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return SchedulingBottomSheetScaffold(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: SchedulingBottomSheetScaffold.titleFontSize(context),
            fontWeight: FontWeight.w700,
            color: AppColors.primaryColor,
            height: 1.35,
          ),
        ),
        SizedBox(height: context.isTablet ? 24 : 18),
        CustomButtonLayout(
          cancelButtonLabel: 'No',
          confirmButtonLabel: 'Yes',
          isForm: false,
          onPressedCancel: () => Navigator.of(context).pop(false),
          onPressedConfirm: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
