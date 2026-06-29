import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_gradient_header.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_guide_card.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_radar_chart.dart';
import 'package:wowcare/presentation/features/assessments/widgets/hierarchical_averages_table.dart';
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
          final overall = AssessmentAggregation.mean(current);

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

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AssessmentGradientHeader(
                  gradient: AssessmentUi.classroomGradient,
                  icon: Icons.groups_rounded,
                  heroTag: 'classroom-avatar-$classroomCode',
                  title: classroom.name,
                  subtitle: [
                    if (classroom.ageGroup.isNotEmpty) classroom.ageGroup,
                    '${studentCodes.length} students',
                  ].join(' · '),
                  overall: overall,
                  monthPicker: MonthPicker(
                    month: state.period.start,
                    onChanged: cubit.setPeriodMonth,
                  ),
                ),
                const SizedBox(height: 16),
                table,
                const SizedBox(height: 16),
                insights,
              ],
            ),
          );
        },
      ),
    );
  }
}

