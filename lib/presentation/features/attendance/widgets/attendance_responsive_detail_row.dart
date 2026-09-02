import 'package:flutter/material.dart';
import 'package:wowcare/shared/common/widgets/app_text_styles.dart';
import 'package:wowcare/shared/utils/responsive_helper.dart';

/// A label/value row with tablet-aware flex ratios, used in the expanded
/// detail section of the student-absent and staff-custom attendance cards —
/// was an identical private `_buildDetailRow`/`_AbsentStudentDetailRow` in
/// both.
class AttendanceResponsiveDetailRow extends StatelessWidget {
  const AttendanceResponsiveDetailRow({
    super.key,
    required this.responsive,
    required this.label,
    required this.value,
  });

  final ResponsiveHelper responsive;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: responsive.isTablet ? 2 : 1,
          child: Text(label, style: AppTextStyles.label),
        ),
        SizedBox(width: responsive.horizontalSpacing / 2),
        Expanded(
          flex: responsive.isTablet ? 3 : 2,
          child: Text(
            value,
            style: AppTextStyles.body,
            textAlign: TextAlign.end,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
