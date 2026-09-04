import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/domain_score_tile.dart';
import 'package:wowcare/presentation/features/assessments/widgets/entrance.dart';
import 'package:wowcare/presentation/features/assessments/widgets/period_picker.dart';

/// Classrooms tab — a period chip and a list of classroom cards showing the
/// period's overall average and per-domain score chips. Tapping a card opens
/// the classroom roll-up via [onOpenClassroom].
class ClassroomsListBody extends StatelessWidget {
  const ClassroomsListBody({super.key, required this.onOpenClassroom});

  final ValueChanged<String> onOpenClassroom;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssessmentsCubit>();
    final gradients = AssessmentUi.classroomCardGradients;
    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: AssessmentPeriodChip(
                period: state.period,
                onChanged: cubit.setPeriodMonth,
                iconColor: AssessmentUi.palette.secondary,
              ),
            ),
            const SizedBox(height: 15),
            if (state.classrooms.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text('No classrooms configured.',
                      style: TextStyle(color: AssessmentUi.inkMuted)),
                ),
              )
            else
              ...state.classrooms.asMap().entries.map((e) => Entrance(
                    index: e.key,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ClassroomCard(
                        classroom: e.value,
                        state: state,
                        gradient: gradients[e.key % gradients.length],
                        onTap: () => onOpenClassroom(e.value.code),
                      ),
                    ),
                  )),
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
    required this.onTap,
  });

  final AssessmentClassroom classroom;
  final AssessmentsState state;
  final Gradient gradient;
  final VoidCallback onTap;

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
    final overallColor = AssessmentUi.scoreAccent(overall);

    final meta = [
      if (classroom.ageGroup.isNotEmpty) classroom.ageGroup,
      '$studentCount ${studentCount == 1 ? 'child' : 'children'}',
    ].join(' · ');

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: AssessmentUi.softSurface(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(Icons.home_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          classroom.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AssessmentUi.ink,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AssessmentUi.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    children: [
                      Text(
                        AssessmentAggregation.formatAverage(overall),
                        style: TextStyle(
                          fontSize: 20,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: overallColor,
                        ),
                      ),
                      Text(
                        records.isEmpty
                            ? 'No data'
                            : AssessmentUi.scoreSummary(overall),
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: AssessmentUi.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (domains.isNotEmpty) ...[
                const SizedBox(height: 13),
                Row(
                  children: domains
                      .map<Widget>((d) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: DomainScoreTile(
                                shortLabel: d.name.split(' ').first,
                                score: AssessmentAggregation.domainAverage(
                                    records, d.id),
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
