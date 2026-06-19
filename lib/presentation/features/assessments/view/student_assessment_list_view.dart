import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/view/student_assessment_profile_screen.dart';
import 'package:wowcare/presentation/features/assessments/widgets/initials_avatar.dart';
import 'package:wowcare/presentation/features/assessments/widgets/month_picker.dart';
import 'package:wowcare/presentation/features/assessments/widgets/score_badge.dart';

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

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
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
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      mainAxisExtent: 188,
                    ),
                    itemCount: students.length,
                    itemBuilder: (context, i) {
                      final student = students[i];
                      return _StudentCard(
                        student: student,
                        domains: domains,
                        state: state,
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
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 240,
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
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openProfile(context),
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
                  seed: student.code,
                  initials: student.initials,
                  imageUrl: student.avatarUrl,
                  radius: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              const TextStyle(fontWeight: FontWeight.w700)),
                      Text(
                        state.classroomByCode(student.classroomCode)?.name ??
                            '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Expanded(
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: domains.map<Widget>((d) {
                    final avg = AssessmentAggregation.domainAverage(
                        records, d.id);
                    return ScoreBadge(label: d.name, score: avg, dense: true);
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _openProfile(context),
                icon: const Icon(Icons.edit_note, size: 18),
                label: const Text('Assess'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.themeColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    context.push(
      StudentAssessmentProfileScreen.routeName,
      extra: <String, dynamic>{'studentCode': student.code},
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
