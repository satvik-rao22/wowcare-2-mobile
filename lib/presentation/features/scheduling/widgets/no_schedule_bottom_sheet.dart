import 'package:flutter/material.dart';

import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

/// Confirmation sheet shown when the user tries to add a shift on a day the
/// selected staff has no work schedule defined for. Tapping Yes signals that
/// the request should be sent with `forceAdd: true`.
class NoScheduleBottomSheet extends StatelessWidget {
  const NoScheduleBottomSheet({
    super.key,
    this.title =
        'This staff has no schedule defined for the selected day. '
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
                title,
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
                cancelButtonLabel: 'No',
                confirmButtonLabel: 'Yes',
                isForm: false,
                onPressedCancel: () => Navigator.of(context).pop(false),
                onPressedConfirm: () => Navigator.of(context).pop(true),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
