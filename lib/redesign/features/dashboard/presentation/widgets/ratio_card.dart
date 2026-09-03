import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/inner_row.dart';

/// Ratio monitoring, the Admin's form (3A2): every classroom, shortfalls
/// first, each one either red and short or quiet and In Ratio.
class RatioCard extends StatelessWidget {
  const RatioCard({required this.rows, super.key});

  final List<RatioRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final short = rows.where((r) => !r.isInRatio).length;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: DashboardSizes.statusBlockGap,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DashboardStrings.ratioMonitoring,
                  style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                ),
              ),
              StatusPill(
                label: short == 0
                    ? DashboardStrings.allInRatio
                    : DashboardStrings.notInRatioCount(short),
                tone: short == 0 ? PillTone.success : PillTone.danger,
                small: true,
              ),
            ],
          ),
          for (final row in rows)
            InnerRow(
              title: DashboardStrings.classroomAndGroup(
                row.classroomName,
                row.groupName,
              ),
              subtitle: DashboardStrings.studentsAndStaff(
                row.students,
                row.staff,
              ),
              fill: row.isInRatio ? c.altWell : c.dangerBg,
              line: row.isInRatio ? null : c.dangerLine,
              subtitleColor: row.isInRatio ? c.ink3 : c.dangerFg,
              barColor: row.isInRatio ? c.success : c.danger,
              flag: row.isInRatio
                  ? AppStrings.inRatio
                  : DashboardStrings.plusStaff(row.staffNeeded),
              flagColor: row.isInRatio ? c.successFg : c.dangerFg,
            ),
        ],
      ),
    );
  }
}
