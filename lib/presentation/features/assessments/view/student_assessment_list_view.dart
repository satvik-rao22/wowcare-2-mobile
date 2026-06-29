import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/view/student_assessment_profile_screen.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_card.dart';
import 'package:wowcare/presentation/features/assessments/widgets/entrance.dart';
import 'package:wowcare/presentation/features/assessments/widgets/initials_avatar.dart';
import 'package:wowcare/presentation/features/assessments/widgets/month_picker.dart';
import 'package:wowcare/presentation/features/assessments/widgets/score_badge.dart';
import 'package:wowcare/presentation/features/assessments/widgets/score_ring.dart';

/// Student Assessments list (PRD §12.1): classroom + month filter and a card
/// grid of students with per-domain score badges and an "Assess" action.
class StudentAssessmentListView extends StatelessWidget {
  const StudentAssessmentListView({super.key});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssessmentsCubit>();
    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        if (state.classrooms.isEmpty) {
          return const _Centered(
              message: 'No classrooms are configured for this school.');
        }

        // Default to the first classroom on first entry (persist to the cubit
        // so the selection survives tab switches).
        final selectedCode =
            state.selectedClassroomCode ?? state.classrooms.first.code;
        if (state.selectedClassroomCode == null) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => cubit.setSelectedClassroom(selectedCode));
        }

        final students = state.studentsInClassroom(selectedCode);
        final domains = state.domainsForClassroom(selectedCode);
        final width = MediaQuery.sizeOf(context).width;

        return ListView(
          padding: AssessmentUi.bodyPadding(width),
          children: [
            _Filters(
              classrooms: state.classrooms,
              selectedCode: selectedCode,
              month: state.period.start,
              onClassroom: (code) => cubit.setSelectedClassroom(code),
              onMonth: cubit.setPeriodMonth,
            ),
            const SizedBox(height: 16),
            if (students.isEmpty)
              const _Centered(message: 'No active students in this classroom.')
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
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: spacing,
                      crossAxisSpacing: spacing,
                      mainAxisExtent:
                          AssessmentUi.cardExtent(constraints.maxWidth),
                    ),
                    itemCount: students.length,
                    itemBuilder: (context, i) {
                      final student = students[i];
                      return Entrance(
                        index: i,
                        child: _StudentCard(
                          student: student,
                          domains: domains,
                          state: state,
                        ),
                      );
                    },
                  );
                },
              ),
          ],
        );
      },
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.classrooms,
    required this.selectedCode,
    required this.month,
    required this.onClassroom,
    required this.onMonth,
  });

  final List<AssessmentClassroom> classrooms;
  final String selectedCode;
  final DateTime month;
  final ValueChanged<String> onClassroom;
  final ValueChanged<DateTime> onMonth;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    // Full-width on tight phones (where 240 would crowd the month picker, and
    // an unbounded Wrap child would overflow), a touch wider on web canvases.
    // A finite width is required because Wrap hands children unbounded width.
    final dropdownWidth = width < AssessmentUi.mobileMax
        ? width - AssessmentUi.gutter(width) * 2
        : (width >= AssessmentUi.tabletMax ? 320.0 : 240.0);
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: dropdownWidth,
          child: DropdownButtonFormField<String>(
            initialValue: selectedCode,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Classroom',
              border: OutlineInputBorder(),
              isDense: true,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
            items: classrooms
                .map((c) => DropdownMenuItem(
                      value: c.code,
                      child: Text(
                        c.ageGroup.isEmpty
                            ? c.name
                            : '${c.name} · ${c.ageGroup}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (v) {
              if (v != null) onClassroom(v);
            },
          ),
        ),
        MonthPicker(month: month, onChanged: onMonth, blockFuture: true),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.domains,
    required this.state,
  });

  final AssessmentStudent student;
  final List<AssessmentDomain> domains;
  final AssessmentsState state;

  @override
  Widget build(BuildContext context) {
    final records = state.studentAssessments(student.code, state.period);
    final overall = AssessmentAggregation.mean(records);
    final accent = AssessmentUi.scoreAccent(overall);
    final width = MediaQuery.sizeOf(context).width;
    final wide = width >= AssessmentUi.tabletMax;

    return AssessmentCard(
      accent: accent,
      onTap: () => _openProfile(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Hero(
                tag: 'student-avatar-${student.code}',
                child: InitialsAvatar(
                  seed: student.code,
                  initials: student.initials,
                  imageUrl: student.avatarUrl,
                  gradient: student.avatarUrl == null
                      ? AssessmentUi.studentGradient
                      : null,
                  radius: AssessmentUi.avatarRadius(width),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: wide ? 16.5 : 15)),
                    const SizedBox(height: 2),
                    Text(
                      AssessmentUi.scoreSummary(overall),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accent,
                      ),
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
                children: domains.map<Widget>((d) {
                  final avg =
                      AssessmentAggregation.domainAverage(records, d.id);
                  return ScoreBadge(label: d.name, score: avg, dense: true);
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _AssessButton(onTap: () => _openProfile(context)),
        ],
      ),
    );
  }

  void _openProfile(BuildContext context) {
    unawaited(context.push(
      StudentAssessmentProfileScreen.routeName,
      extra: <String, dynamic>{'studentCode': student.code},
    ));
  }
}

/// Compact full-width gradient "Assess" action used on each student card.
class _AssessButton extends StatelessWidget {
  const _AssessButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AssessmentUi.brandGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const SizedBox(
            height: 44,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.edit_note_rounded, size: 18, color: Colors.white),
                  SizedBox(width: 6),
                  Text(
                    'Assess',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Centered extends StatelessWidget {
  const _Centered({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600)),
      ),
    );
  }
}
