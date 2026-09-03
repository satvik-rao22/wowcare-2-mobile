import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/dot_pill.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/inner_row.dart';
import 'package:wowcare/redesign/features/dashboard/presentation/widgets/ratio_ring.dart';

/// Ratio monitoring, the Staff form (3S1): one ring for the classroom they
/// are actually standing in, and a quiet row for anything they only cover.
class StaffRatioCard extends StatelessWidget {
  const StaffRatioCard({required this.rows, super.key});

  final List<RatioRow> rows;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    if (rows.isEmpty) return const SizedBox.shrink();

    final own = rows.first;
    final covering = rows.skip(1);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: DashboardSizes.timeCardGap,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DashboardStrings.ratioMonitoring,
                  style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                ),
              ),
              Text(
                DashboardStrings.myClassrooms,
                style: AppTextStyles.sectionLink.copyWith(color: c.ink3),
              ),
            ],
          ),
          Row(
            spacing: DashboardSizes.ratioRingGap,
            children: <Widget>[
              RatioRing(
                present: own.students,
                total: own.enrolled ?? own.students,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: DashboardSizes.ratioClassroomTextGap,
                  children: <Widget>[
                    Text(
                      DashboardStrings.classroomAndGroup(
                        own.classroomName,
                        own.groupName,
                      ),
                      style: AppTextStyles.rowName.copyWith(color: c.ink),
                    ),
                    DotPill(
                      label: own.isInRatio
                          ? AppStrings.inRatio
                          : AppStrings.notInRatio,
                      fill: own.isInRatio ? c.successBg : c.dangerBg,
                      ink: own.isInRatio ? c.successFg : c.dangerFg,
                      dot: own.isInRatio ? c.success : c.danger,
                    ),
                    Text(
                      DashboardStrings.studentsAndStaff(
                        own.students,
                        own.staff,
                      ),
                      style: AppTextStyles.rowSub.copyWith(color: c.ink3),
                    ),
                  ],
                ),
              ),
            ],
          ),
          for (final row in covering)
            InnerRow(
              title: row.coveringFrom == null
                  ? DashboardStrings.coveringNoTime(row.classroomName)
                  : DashboardStrings.covering(
                      row.classroomName,
                      row.coveringFrom!,
                    ),
              subtitle: DashboardStrings.studentsAndStaff(
                row.students,
                row.staff,
              ),
              fill: c.staffBg,
              line: c.staffLine,
              subtitleColor: c.staffFg,
              barColor: c.staff,
              flag: row.isInRatio
                  ? AppStrings.inRatio
                  : DashboardStrings.plusStaff(row.staffNeeded),
              flagColor: c.staffFg,
            ),
        ],
      ),
    );
  }
}
