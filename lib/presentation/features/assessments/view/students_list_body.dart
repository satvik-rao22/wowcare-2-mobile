import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_access.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_filter_sheet.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_option_sheet.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_scope_chip.dart';
import 'package:wowcare/presentation/features/assessments/widgets/entrance.dart';
import 'package:wowcare/presentation/features/assessments/widgets/initials_avatar.dart';
import 'package:wowcare/presentation/features/assessments/widgets/period_picker.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// Students tab — classroom + period scope, a "scored" summary line, and a list
/// of student cards (status pill + per-domain score chips). Tapping a card opens
/// the in-place scoring stepper via [onOpenStudent].
class StudentsListBody extends StatelessWidget {
  const StudentsListBody({super.key, required this.onOpenStudent});

  final ValueChanged<String> onOpenStudent;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssessmentsCubit>();
    final canSelectAny =
        AssessmentAccess.canSelectAnyClassroom(context.watch<RoleCubit>());

    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        if (state.classrooms.isEmpty) {
          return const _Empty(
              message: 'No classrooms are configured for this school.');
        }

        final selectedCode =
            state.selectedClassroomCode ?? state.classrooms.first.code;
        if (state.selectedClassroomCode == null) {
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => cubit.setSelectedClassroom(selectedCode));
        }

        final classroom = state.classroomByCode(selectedCode);
        final students = state.visibleStudentsInClassroom(selectedCode);
        final domains = state.domainsForClassroom(selectedCode);
        final assessedCount = students
            .where((s) => state.studentAssessments(s.code, state.period).isNotEmpty)
            .length;
        final activeFilterCount = state.tagFilter.length +
            (state.statusFilter.length == 1 &&
                    state.statusFilter.contains('ACTIVE')
                ? 0
                : state.statusFilter.length);

        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: AssessmentScopeChip(
                    icon: Icons.home_rounded,
                    eyebrow: 'CLASSROOM',
                    value: classroom?.name ?? '—',
                    expand: true,
                    locked: !canSelectAny,
                    onTap: canSelectAny
                        ? () => _pickClassroom(context, cubit, state, selectedCode)
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                AssessmentPeriodChip(
                  period: state.period,
                  onChanged: cubit.setPeriodMonth,
                ),
                const SizedBox(width: 8),
                _FilterButton(
                  activeCount: activeFilterCount,
                  onTap: () => showAssessmentFilterSheet(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              '$assessedCount of ${students.length} assessed · '
              '${AssessmentUi.shortMonthLabel(state.period.start)}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF8A8398),
              ),
            ),
            const SizedBox(height: 12),
            if (students.isEmpty)
              const _Empty(message: 'No students match the current filters.')
            else
              ...students.asMap().entries.map((e) => Entrance(
                    index: e.key,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _StudentCard(
                        student: e.value,
                        domains: domains,
                        state: state,
                        onTap: () => onOpenStudent(e.value.code),
                      ),
                    ),
                  )),
          ],
        );
      },
    );
  }

  Future<void> _pickClassroom(
    BuildContext context,
    AssessmentsCubit cubit,
    AssessmentsState state,
    String selectedCode,
  ) async {
    final picked = await AssessmentOptionSheet.show<String>(
      context,
      title: 'Choose classroom',
      options: state.classrooms
          .map((c) => AssessmentOption<String>(
                value: c.code,
                title: c.name,
                subtitle: c.ageGroup.isEmpty ? null : c.ageGroup,
                selected: c.code == selectedCode,
              ))
          .toList(),
    );
    if (picked != null) cubit.setSelectedClassroom(picked);
  }
}

/// Opens [showAssessmentFilterSheet]; shows a small badge when any filter is
/// active beyond the default (active-only, no tags).
class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.activeCount, required this.onTap});

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AssessmentUi.hairline),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              const Icon(Icons.tune_rounded,
                  size: 19, color: AssessmentUi.ink),
              if (activeCount > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.themeColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$activeCount',
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({
    required this.student,
    required this.domains,
    required this.state,
    required this.onTap,
  });

  final AssessmentStudent student;
  final List<AssessmentDomain> domains;
  final AssessmentsState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final records = state.studentAssessments(student.code, state.period);
    final overall = AssessmentAggregation.mean(records);
    final assessed = records.isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
          decoration: AssessmentUi.softSurface(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsAvatar(
                    seed: student.code,
                    initials: student.initials,
                    imageUrl: student.avatarUrl,
                    gradient: student.avatarUrl == null
                        ? AssessmentUi.studentGradient
                        : null,
                    radius: 26,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AssessmentUi.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _StatusPill(assessed: assessed),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                AssessmentUi.scoreSummary(overall),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: AssessmentUi.inkMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (domains.isNotEmpty) ...[
                const SizedBox(height: 11),
                Row(
                  children: domains
                      .map<Widget>((d) => Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(right: 5),
                              child: _DomainScoreBadge(
                                domainName: d.name,
                                emoji: AssessmentUi.domainEmoji(d.id),
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

/// Compact domain glyph + score shown on a student card (replaces the
/// previous domain-name label to save space); long-pressing reveals the full
/// domain name via [Tooltip] (Flutter's default trigger mode on mobile).
class _DomainScoreBadge extends StatelessWidget {
  const _DomainScoreBadge({
    required this.domainName,
    required this.emoji,
    required this.score,
  });

  final String domainName;
  final String emoji;
  final double? score;

  @override
  Widget build(BuildContext context) {
    final style = AssessmentUi.badgeStyle(score);
    return Tooltip(
      message: domainName,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: style.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 13, height: 1.1)),
            const SizedBox(height: 1),
            Text(
              score == null ? '–' : score!.toStringAsFixed(1),
              style: TextStyle(
                fontSize: 12,
                height: 1.1,
                fontWeight: FontWeight.w800,
                color: style.foreground,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.assessed});

  final bool assessed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: assessed ? const Color(0xFFECFDF3) : const Color(0xFFF1EFF8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        assessed ? 'Assessed' : 'Not started',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: assessed ? const Color(0xFF15803D) : const Color(0xFF8A8398),
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: AssessmentUi.inkMuted),
        ),
      ),
    );
  }
}
