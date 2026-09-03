import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/inner_row.dart';

/// Classroom shifts today (3A2). A shift is either Filled and quiet, or Open
/// and sun, and the sun one names what it is short of.
class ShiftsCard extends StatelessWidget {
  const ShiftsCard({required this.rows, super.key});

  final List<ShiftRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: DashboardSizes.summaryTileGap,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DashboardStrings.classroomShifts,
                  style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                ),
              ),
              Text(
                DashboardStrings.today,
                style: AppTextStyles.sectionLink.copyWith(color: c.ink3),
              ),
            ],
          ),
          for (final row in rows)
            InnerRow(
              title: row.classroomName,
              subtitle: row.isFilled
                  ? DashboardStrings.shiftFilledLine(
                      row.window,
                      row.staffNames ?? '',
                    )
                  : DashboardStrings.shiftOpenLine(
                      row.window,
                      row.staffNeeded,
                      row.staffScheduled,
                    ),
              fill: row.isFilled ? c.altWell : c.staffBg,
              line: row.isFilled ? null : c.staffLine,
              subtitleColor: row.isFilled ? c.ink3 : c.staffFg,
              trailing: StatusPill(
                label: row.isFilled
                    ? DashboardStrings.filled
                    : DashboardStrings.open,
                foreground: row.isFilled ? c.successFg : c.ink,
                background: row.isFilled ? c.successBg : c.staff,
                small: true,
              ),
            ),
        ],
      ),
    );
  }
}
