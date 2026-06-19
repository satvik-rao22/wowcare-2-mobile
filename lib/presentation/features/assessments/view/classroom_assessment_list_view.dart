import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/view/classroom_assessment_profile_screen.dart';
import 'package:wowcare/presentation/features/assessments/widgets/initials_avatar.dart';
import 'package:wowcare/presentation/features/assessments/widgets/month_picker.dart';
import 'package:wowcare/presentation/features/assessments/widgets/score_badge.dart';

/// Classroom Assessments list (PRD §13.1): a card grid of classrooms showing
/// average domain scores for the selected period, with a month picker.
class ClassroomAssessmentListView extends StatelessWidget {
  const ClassroomAssessmentListView({super.key});

  static const _gradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
  );

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssessmentsCubit>();
    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text('Classroom Assessments',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                MonthPicker(
                  month: state.period.start,
                  onChanged: cubit.setPeriodMonth,
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (state.classrooms.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text('No classrooms configured.',
                      style: TextStyle(color: Colors.grey.shade600)),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns =
                      AssessmentUi.gridColumns(constraints.maxWidth);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 210,
                    ),
                    itemCount: state.classrooms.length,
                    itemBuilder: (context, i) => _ClassroomCard(
                      classroom: state.classrooms[i],
                      state: state,
                      gradient: _gradient,
                    ),
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _ClassroomCard extends StatelessWidget {
  const _ClassroomCard({
    required this.classroom,
    required this.state,
    required this.gradient,
  });

  final AssessmentClassroom classroom;
  final AssessmentsState state;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    final studentCount = state.studentCountIn(classroom.code);
    final domains = state.domainsForClassroom(classroom.code);
    final studentCodes =
        state.studentsInClassroom(classroom.code).map((s) => s.code).toSet();
    final Iterable<Assessment> records = state
        .assessmentsForPeriod(state.period)
        .where((a) => studentCodes.contains(a.studentId));

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push(
        ClassroomAssessmentProfileScreen.routeName,
        extra: <String, dynamic>{'classroomCode': classroom.code},
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InitialsAvatar(
                  seed: classroom.code,
                  initials: '',
                  icon: Icons.groups_outlined,
                  gradient: gradient,
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(classroom.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      if (classroom.ageGroup.isNotEmpty)
                        Text(classroom.ageGroup,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text('$studentCount',
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1D4ED8),
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const Divider(height: 18),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: domains.map((d) {
                    final avg =
                        AssessmentAggregation.domainAverage(records, d.id);
                    return ScoreBadge(label: d.name, score: avg, dense: true);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
