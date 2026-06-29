import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_radar_chart.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_roll_up_hero.dart';
import 'package:wowcare/presentation/features/assessments/widgets/averages_tree.dart';

/// Classroom roll-up — gradient hero, a period-comparison radar, and a
/// hierarchical Domain → Subdomain → Milestone averages tree, all scoped to the
/// classroom's students for the active period. Read-only.
class ClassroomProfileBody extends StatelessWidget {
  const ClassroomProfileBody({super.key, required this.classroomCode});

  final String classroomCode;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        final classroom = state.classroomByCode(classroomCode);
        if (classroom == null) {
          return const Center(child: Text('Classroom not found.'));
        }
        final domains = state.domainsForClassroom(classroomCode);
        final studentCodes = state
            .studentsInClassroom(classroomCode)
            .map((s) => s.code)
            .toSet();
        Iterable<Assessment> scoped(period) => state
            .assessmentsForPeriod(period)
            .where((a) => studentCodes.contains(a.studentId));
        final current = scoped(state.period);
        final previous = scoped(state.period.previous);
        final overall = AssessmentAggregation.mean(current);
        final radar = AssessmentAggregation.radarData(
          activeDomains: domains,
          currentRecords: current,
          previousRecords: previous,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          children: [
            AssessmentRollUpHero(
              gradient: AssessmentUi.classroomGradient,
              icon: Icons.home_rounded,
              title: classroom.name,
              meta: [
                if (classroom.ageGroup.isNotEmpty) classroom.ageGroup,
                '${studentCodes.length} children',
                AssessmentUi.shortMonthLabel(state.period.start),
              ].join(' · '),
              overall: overall,
            ),
            const SizedBox(height: 14),
            _RadarCard(
              title: 'Domain averages — period comparison',
              data: radar,
              state: state,
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: AssessmentUi.softSurface(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hierarchical averages',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AssessmentUi.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Tap a domain to see subdomain & milestone detail',
                    style: TextStyle(fontSize: 11.5, color: AssessmentUi.inkMuted),
                  ),
                  const SizedBox(height: 12),
                  AssessmentAveragesTree(
                    domains: domains,
                    records: current,
                    showMilestones: true,
                    milestoneFilter: (m) => m.isAssignedTo(classroomCode),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// A radar card with the standard month-vs-previous-month legend header.
class _RadarCard extends StatelessWidget {
  const _RadarCard({
    required this.title,
    required this.data,
    required this.state,
  });

  final String title;
  final List<RadarDatum> data;
  final AssessmentsState state;

  @override
  Widget build(BuildContext context) {
    return AssessmentRadarChart(
      title: title,
      data: data,
      currentLabel: AssessmentUi.shortMonthLabel(state.period.start),
      previousLabel: AssessmentUi.shortMonthLabel(state.period.previous.start),
    );
  }
}
