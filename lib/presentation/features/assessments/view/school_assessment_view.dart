import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_gradient_header.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_guide_card.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_radar_chart.dart';
import 'package:wowcare/presentation/features/assessments/widgets/hierarchical_averages_table.dart';
import 'package:wowcare/presentation/features/assessments/widgets/month_picker.dart';

/// School Assessment dashboard (PRD §14): school-wide domain/subdomain/milestone
/// averages aggregated across all classrooms, a statistics card, a radar chart,
/// and the scale guide. Read-only.
class SchoolAssessmentView extends StatelessWidget {
  const SchoolAssessmentView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssessmentsCubit>();
    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        final domains = state.activeDomains;
        final current = state.assessmentsForPeriod(state.period);
        final previous = state.assessmentsForPeriod(state.period.previous);
        final activeStudents = state.students.where((s) => s.isActive).length;
        final overall = AssessmentAggregation.mean(current);

        final radar = AssessmentAggregation.radarData(
          activeDomains: domains,
          currentRecords: current,
          previousRecords: previous,
        );

        final table = HierarchicalAveragesTable(
          title: 'School-Wide Average Scores',
          domains: domains,
          records: current,
        );
        final insights = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AssessmentRadarChart(
              title: 'School-Wide Progress',
              data: radar,
              currentLabel: AssessmentUi.shortMonthLabel(state.period.start),
              previousLabel:
                  AssessmentUi.shortMonthLabel(state.period.previous.start),
            ),
            const SizedBox(height: 16),
            const AssessmentGuideCard(),
          ],
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            AssessmentGradientHeader(
              gradient: AssessmentUi.schoolGradient,
              icon: Icons.school_rounded,
              title: 'School Assessment',
              subtitle: 'Across all classrooms',
              overall: overall,
              monthPicker: MonthPicker(
                month: state.period.start,
                onChanged: cubit.setPeriodMonth,
              ),
            ),
            const SizedBox(height: 14),
            _StatsCard(
              classrooms: state.classrooms.length,
              students: activeStudents,
              domains: domains.length,
              assessments: current.length,
            ),
            const SizedBox(height: 16),
            table,
            const SizedBox(height: 16),
            insights,
          ],
        );
      },
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard({
    required this.classrooms,
    required this.students,
    required this.domains,
    required this.assessments,
  });

  final int classrooms;
  final int students;
  final int domains;
  final int assessments;

  @override
  Widget build(BuildContext context) {
    final items = <_StatData>[
      _StatData(Icons.meeting_room_rounded, 'Classrooms', classrooms,
          const Color(0xFF6366F1)),
      _StatData(Icons.face_rounded, 'Students', students,
          const Color(0xFF3B82F6)),
      _StatData(Icons.account_tree_rounded, 'Domains', domains,
          const Color(0xFF8B5CF6)),
      _StatData(Icons.fact_check_rounded, 'Assessments', assessments,
          const Color(0xFF16A34A)),
    ];
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: AssessmentUi.softSurface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insights_rounded,
                    size: 19, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 10),
              const Text('Assessment Statistics', style: AssessmentUi.cardTitle),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 520 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              childAspectRatio: 2.5,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: items.map((e) => _StatTile(data: e)).toList(),
            );
          }),
        ],
      ),
    );
  }
}

class _StatData {
  const _StatData(this.icon, this.label, this.value, this.color);
  final IconData icon;
  final String label;
  final int value;
  final Color color;
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.data});

  final _StatData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: data.color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, size: 19, color: data.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: data.value.toDouble()),
                  duration: const Duration(milliseconds: 900),
                  curve: Curves.easeOutCubic,
                  builder: (context, v, _) => Text(
                    '${v.round()}',
                    style: TextStyle(
                        fontSize: 20,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        color: data.color),
                  ),
                ),
                Text(data.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
