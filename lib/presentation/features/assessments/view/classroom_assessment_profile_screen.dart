import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_guide_card.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_radar_chart.dart';
import 'package:wowcare/presentation/features/assessments/widgets/hierarchical_averages_table.dart';
import 'package:wowcare/presentation/features/assessments/widgets/initials_avatar.dart';
import 'package:wowcare/presentation/features/assessments/widgets/month_picker.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

/// Classroom Assessment Profile (PRD §13.2): read-only domain/subdomain/
/// milestone averages, a period-over-period radar chart, and the scale guide.
class ClassroomAssessmentProfileScreen extends StatelessWidget {
  const ClassroomAssessmentProfileScreen({
    super.key,
    required this.classroomCode,
  });

  static const String routeName = '/dashboard/assessments/classroom';

  final String classroomCode;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssessmentsCubit>();
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      bodyPadding: EdgeInsets.zero,
      body: BlocBuilder<AssessmentsCubit, AssessmentsState>(
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

          final radar = AssessmentAggregation.radarData(
            activeDomains: domains,
            currentRecords: current,
            previousRecords: previous,
          );

          final table = HierarchicalAveragesTable(
            title: 'Average Scores by Domain',
            domains: domains,
            records: current,
            milestoneFilter: (m) => m.isAssignedTo(classroomCode),
          );
          final insights = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AssessmentRadarChart(
                title: 'Classroom Progress',
                data: radar,
                currentLabel:
                    AssessmentUi.shortMonthLabel(state.period.start),
                previousLabel:
                    AssessmentUi.shortMonthLabel(state.period.previous.start),
              ),
              const SizedBox(height: 16),
              const AssessmentGuideCard(),
            ],
          );

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = AssessmentUi.isDesktop(constraints.maxWidth);
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(
                      name: classroom.name,
                      ageGroup: classroom.ageGroup,
                      studentCount: studentCodes.length,
                      month: state.period.start,
                      onMonth: cubit.setPeriodMonth,
                    ),
                    const SizedBox(height: 12),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 2, child: table),
                          const SizedBox(width: 16),
                          Expanded(flex: 1, child: insights),
                        ],
                      )
                    else ...[
                      table,
                      const SizedBox(height: 16),
                      insights,
                    ],
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.name,
    required this.ageGroup,
    required this.studentCount,
    required this.month,
    required this.onMonth,
  });

  final String name;
  final String ageGroup;
  final int studentCount;
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
            children: [
              const InitialsAvatar(
                seed: 'classroom',
                initials: '',
                icon: Icons.groups_outlined,
                gradient: LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)]),
                radius: 24,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.w700)),
                  Text(
                    [
                      if (ageGroup.isNotEmpty) ageGroup,
                      '$studentCount students',
                    ].join(' · '),
                    style:
                        TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ],
          ),
          MonthPicker(month: month, onChanged: onMonth),
        ],
      ),
    );
  }
}
