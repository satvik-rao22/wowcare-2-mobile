import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_text_styles.dart';

/// Small indigo heading above a group of report filter fields.
///
/// Was declared privately, byte-for-byte identically, in both
/// `staff_details_report_screen.dart` and
/// `students_and_family_report_screen.dart` (§6.2).
///
/// Not to be confused with the `_SectionLabel` in
/// `communication/shared/widgets/message_info_dialog.dart`: that one renders
/// at 12/w700 in `AppColors.primaryColor` at 60% alpha, so the two are not
/// interchangeable and were deliberately not merged.
class ReportSectionLabel extends StatelessWidget {
  const ReportSectionLabel({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: AppTextStyles.reportsHeading(
        fontSize: 13,
      ).copyWith(color: AppColors.reportsAccentColor, letterSpacing: 0.4),
    );
  }
}
