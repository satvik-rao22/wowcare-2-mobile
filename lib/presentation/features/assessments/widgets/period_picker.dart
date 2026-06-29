import 'package:flutter/material.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_option_sheet.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_scope_chip.dart';

/// Period scope chip — shows the selected assessment month and opens a bottom
/// sheet of recent months (current month back one year). Future months are
/// excluded for entry contexts (VR-MP-01), matching the redesign's locked look.
class AssessmentPeriodChip extends StatelessWidget {
  const AssessmentPeriodChip({
    super.key,
    required this.period,
    required this.onChanged,
    this.iconColor,
  });

  final AssessmentPeriod period;
  final ValueChanged<DateTime> onChanged;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return AssessmentScopeChip(
      icon: Icons.calendar_today_rounded,
      eyebrow: 'PERIOD',
      value: AssessmentUi.shortMonthLabel(period.start),
      iconColor: iconColor,
      onTap: () => _pick(context),
    );
  }

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month, 1);
    // The 12 most recent months, newest first.
    final months = List<DateTime>.generate(
      12,
      (i) => DateTime(current.year, current.month - i, 1),
    );
    final picked = await AssessmentOptionSheet.show<DateTime>(
      context,
      title: 'Assessment period',
      subtitle: 'Future months are locked for new entries',
      options: months
          .map((m) => AssessmentOption<DateTime>(
                value: m,
                title: AssessmentUi.monthLabel(m),
                selected:
                    m.year == period.start.year && m.month == period.start.month,
              ))
          .toList(),
    );
    if (picked != null) onChanged(picked);
  }
}
