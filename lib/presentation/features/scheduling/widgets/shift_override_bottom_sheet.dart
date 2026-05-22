import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/shared/common/widgets/custom_button_layout.dart';

/// Confirmation sheet shown after `GET /api/v1/staff/staff-shifts` returns
/// conflicting shifts for the same staff/date range that the user is about to
/// create. Matches the design in the PRD screenshot:
///   "Shifts already exist for this staff for the selected date range,
///    do you still want to override as per the new changes?"
///   • <bulleted conflict dates>
///   [ No ]   [ Yes ]
class ShiftOverrideBottomSheet extends StatelessWidget {
  const ShiftOverrideBottomSheet({
    super.key,
    required this.conflictDates,
    this.title =
        'Shifts already exist for this staff for the selected date range, '
        'do you still want to override as per the new changes?',
  });

  final List<DateTime> conflictDates;
  final String title;

  /// Convenience helper: shows the sheet and returns `true` if the user taps
  /// Yes, `false` (or sheet dismiss) otherwise.
  static Future<bool> show(
    BuildContext context, {
    required List<DateTime> conflictDates,
  }) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShiftOverrideBottomSheet(conflictDates: conflictDates),
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

    final formatter = DateFormat('MMM d, yyyy');

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
              if (conflictDates.isNotEmpty) ...[
                const SizedBox(height: 14),
                const Text(
                  'Conflicts:',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF8B7B89),
                  ),
                ),
                const SizedBox(height: 6),
                for (final date in conflictDates)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(width: 6),
                        const Text(
                          '•',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 14,
                            color: AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            formatter.format(date),
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
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
