import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/view/classroom_assessment_profile_screen.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_card.dart';
import 'package:wowcare/presentation/features/assessments/widgets/entrance.dart';
import 'package:wowcare/presentation/features/assessments/widgets/initials_avatar.dart';
import 'package:wowcare/presentation/features/assessments/widgets/month_picker.dart';
import 'package:wowcare/presentation/features/assessments/widgets/score_badge.dart';
import 'package:wowcare/presentation/features/assessments/widgets/score_ring.dart';

/// Classroom Assessments list (PRD §13.1): a card grid of classrooms showing
/// average domain scores for the selected period, with a month picker.
class ClassroomAssessmentListView extends StatelessWidget {
  const ClassroomAssessmentListView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssessmentsCubit>();
    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        final width = MediaQuery.sizeOf(context).width;
        return ListView(
          padding: AssessmentUi.bodyPadding(width),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Classroom Assessments',
                      style: AssessmentUi.sectionTitleStyle(width)),
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
                  final spacing =
                      constraints.maxWidth >= AssessmentUi.tabletMax ? 18.0 : 14.0;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      mainAxisExtent:
                          AssessmentUi.cardExtent(constraints.maxWidth),
                    ),
                    itemCount: state.classrooms.length,
                    itemBuilder: (context, i) => Entrance(
                      index: i,
                      child: _ClassroomCard(
                        classroom: state.classrooms[i],
                        state: state,
                      ),
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
  });

  final AssessmentClassroom classroom;
  final AssessmentsState state;

  @override
  Widget build(BuildContext context) {
    final studentCount = state.studentCountIn(classroom.code);
    final domains = state.domainsForClassroom(classroom.code);
    final studentCodes =
        state.studentsInClassroom(classroom.code).map((s) => s.code).toSet();
    final Iterable<Assessment> records = state
        .assessmentsForPeriod(state.period)
        .where((a) => studentCodes.contains(a.studentId));
    final overall = AssessmentAggregation.mean(records);
    final accent = AssessmentUi.scoreAccent(overall);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= AssessmentUi.tabletMax;

    return AssessmentCard(
      accent: accent,
      onTap: () => context.push(
        ClassroomAssessmentProfileScreen.routeName,
        extra: <String, dynamic>{'classroomCode': classroom.code},
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'classroom-avatar-${classroom.code}',
                child: InitialsAvatar(
                  seed: classroom.code,
                  initials: '',
                  icon: Icons.groups_rounded,
                  gradient: AssessmentUi.classroomGradient,
                  radius: AssessmentUi.avatarRadius(width),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(classroom.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: wide ? 16.5 : 15)),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        _StudentCountChip(count: studentCount),
                        if (classroom.ageGroup.isNotEmpty) ...[
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              classroom.ageGroup,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ScoreRing(score: overall, size: wide ? 56 : 50),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: AssessmentUi.wrapSpacing(width),
                runSpacing: AssessmentUi.wrapSpacing(width),
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
    );
  }
}

/// Small "N students · age group" pill on classroom cards.
class _StudentCountChip extends StatelessWidget {
  const _StudentCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        color: AssessmentUi.classroomGradientColors.last.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_rounded,
              size: 13, color: AssessmentUi.classroomGradientColors.last),
          const SizedBox(width: 3),
          Text(
            '$count student${count == 1 ? '' : 's'}',
            style: TextStyle(
              fontSize: 11.5,
              color: AssessmentUi.classroomGradientColors.last,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
