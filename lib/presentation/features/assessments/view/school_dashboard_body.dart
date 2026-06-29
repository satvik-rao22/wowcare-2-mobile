import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_radar_chart.dart';
import 'package:wowcare/presentation/features/assessments/widgets/averages_tree.dart';
import 'package:wowcare/presentation/features/assessments/widgets/period_picker.dart';

/// School tab — period scope, a 2×2 statistics grid, a school-wide
/// period-comparison radar, and a Domain → Subdomain breakdown tree aggregated
/// across every classroom. Read-only.
class SchoolDashboardBody extends StatelessWidget {
  const SchoolDashboardBody({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssessmentsCubit>();
    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        final domains = state.activeDomains;
        final current = state.assessmentsForPeriod(state.period);
        final previous = state.assessmentsForPeriod(state.period.previous);
        final activeStudents = state.students.where((s) => s.isActive).length;
        final radar = AssessmentAggregation.radarData(
          activeDomains: domains,
          currentRecords: current,
          previousRecords: previous,
        );

        final stats = <_Stat>[
          _Stat('${state.classrooms.length}', 'Classrooms',
              const Color(0xFF5978F7)),
          _Stat('$activeStudents', 'Students', const Color(0xFF8B5CF6)),
          _Stat('${domains.length}', 'Active domains', const Color(0xFF3B82F6)),
          _Stat('${current.length}', 'Assessments this period',
              const Color(0xFF16A34A)),
        ];

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AssessmentPeriodChip(
                period: state.period,
                onChanged: cubit.setPeriodMonth,
                iconColor: const Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.4,
              children: stats.map((s) => _StatTile(stat: s)).toList(),
            ),
            const SizedBox(height: 14),
            AssessmentRadarChart(
              title: 'School-wide domain averages',
              data: radar,
              currentLabel: AssessmentUi.shortMonthLabel(state.period.start),
              previousLabel:
                  AssessmentUi.shortMonthLabel(state.period.previous.start),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AssessmentUi.softSurface(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Domain breakdown',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AssessmentUi.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  AssessmentAveragesTree(domains: domains, records: current),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Stat {
  const _Stat(this.value, this.label, this.color);
  final String value;
  final String label;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.stat});

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: AssessmentUi.softSurface(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            stat.value,
            style: TextStyle(
              fontSize: 24,
              height: 1,
              fontWeight: FontWeight.w800,
              color: stat.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            stat.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: Color(0xFF8A8398),
            ),
          ),
        ],
      ),
    );
  }
}
