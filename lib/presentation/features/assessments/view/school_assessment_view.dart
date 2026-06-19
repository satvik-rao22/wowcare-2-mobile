import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_guide_card.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_radar_chart.dart';
import 'package:wowcare/presentation/features/assessments/widgets/hierarchical_averages_table.dart';
import 'package:wowcare/presentation/features/assessments/widgets/initials_avatar.dart';
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
            _Header(month: state.period.start, onMonth: cubit.setPeriodMonth),
            const SizedBox(height: 12),
            _StatsCard(
              classrooms: state.classrooms.length,
              students: activeStudents,
              domains: domains.length,
              assessments: current.length,
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = AssessmentUi.isDesktop(constraints.maxWidth);
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 2, child: table),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: insights),
                    ],
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [table, const SizedBox(height: 16), insights],
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.month, required this.onMonth});

  final DateTime month;
  final ValueChanged<DateTime> onMonth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              InitialsAvatar(
                seed: 'school',
                initials: '',
                icon: Icons.school_outlined,
                gradient: LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                radius: 24,
              ),
              SizedBox(width: 12),
              Text('School Assessment',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            ],
          ),
          MonthPicker(month: month, onChanged: onMonth),
        ],
      ),
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
    final items = <(_StatKind, String, int)>[
      (_StatKind.classrooms, 'Classrooms', classrooms),
      (_StatKind.students, 'Students', students),
      (_StatKind.domains, 'Domains', domains),
      (_StatKind.assessments, 'Assessments', assessments),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Assessment Statistics',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 520 ? 4 : 2;
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: columns,
              childAspectRatio: 2.4,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              children: items
                  .map((e) => _StatTile(label: e.$2, value: e.$3))
                  .toList(),
            );
          }),
        ],
      ),
    );
  }
}

enum _StatKind { classrooms, students, domains, assessments }

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.themeColor)),
          Text(label,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}
