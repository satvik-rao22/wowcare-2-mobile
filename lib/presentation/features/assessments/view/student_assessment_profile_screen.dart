import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_gradient_header.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_guide_card.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_radar_chart.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_scale_selector.dart';
import 'package:wowcare/presentation/features/assessments/widgets/month_picker.dart';
import 'package:wowcare/presentation/features/assessments/widgets/score_badge.dart';
import 'package:wowcare/shared/common/widgets/custom_scaffold.dart';

/// Student Assessment Profile (PRD §12.2): per-milestone 1–5 scoring with notes,
/// domain-level "Copy to All Milestones", bulk Save All (upsert), and a
/// period-over-period radar chart. Responsive: two columns on desktop, stacked
/// on phones/tablets.
class StudentAssessmentProfileScreen extends StatefulWidget {
  const StudentAssessmentProfileScreen({super.key, required this.studentCode});

  static const String routeName = '/dashboard/assessments/student';

  final String studentCode;

  @override
  State<StudentAssessmentProfileScreen> createState() =>
      _StudentAssessmentProfileScreenState();
}

class _StudentAssessmentProfileScreenState
    extends State<StudentAssessmentProfileScreen> {
  final Map<String, int> _scores = {};
  final Map<String, String> _notes = {};
  final Map<String, int> _domainScore = {};
  DateTime? _seededFor;

  /// Seeds local draft maps from persisted scores for the active period. Run
  /// once per (re)selected period so existing scores pre-populate the scales.
  void _ensureSeeded(AssessmentsState state) {
    if (_seededFor == state.period.start) return;
    _seededFor = state.period.start;
    _scores.clear();
    _notes.clear();
    _domainScore.clear();
    for (final a in state.studentAssessments(widget.studentCode, state.period)) {
      _scores[a.milestoneId] = a.score;
      if ((a.notes ?? '').isNotEmpty) _notes[a.milestoneId] = a.notes!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GlobalScaffold(
      hasBackButton: true,
      showCustomNavigationBar: false,
      bodyPadding: EdgeInsets.zero,
      body: BlocBuilder<AssessmentsCubit, AssessmentsState>(
        builder: (context, state) {
          final student = state.studentByCode(widget.studentCode);
          if (student == null) {
            return const Center(child: Text('Student not found.'));
          }
          _ensureSeeded(state);
          final domains = state.domainsForClassroom(student.classroomCode);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildScoringColumn(context, state, student, domains),
                const SizedBox(height: 16),
                _buildInsightsColumn(state, student, domains),
              ],
            ),
          );
        },
      ),
    );
  }

  // ----------------------------------------------------------- scoring column

  Widget _buildScoringColumn(
    BuildContext context,
    AssessmentsState state,
    AssessmentStudent student,
    List<AssessmentDomain> domains,
  ) {
    final cubit = context.read<AssessmentsCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _header(context, state, student, cubit),
        const SizedBox(height: 14),
        if (domains.isEmpty)
          _emptyMilestones()
        else
          ...domains.asMap().entries.map((e) => _DomainScoringCard(
                domain: e.value,
                classroomCode: student.classroomCode,
                state: state,
                scores: _scores,
                notes: _notes,
                domainScore: _domainScore,
                initiallyExpanded: e.key == 0,
                onChanged: () => setState(() {}),
              )),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Cancel'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: _GradientPrimaryButton(
                label: 'Save All Assessments',
                icon: Icons.save_rounded,
                loading: state.isSaving,
                onTap: state.isSaving || domains.isEmpty
                    ? null
                    : () => _saveAll(context, cubit),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _header(
    BuildContext context,
    AssessmentsState state,
    AssessmentStudent student,
    AssessmentsCubit cubit,
  ) {
    // Live overall from the in-progress draft so the score updates as the
    // educator taps the scales.
    final draftOverall = _scores.isEmpty
        ? null
        : _scores.values.reduce((a, b) => a + b) / _scores.length;
    return AssessmentGradientHeader(
      gradient: AssessmentUi.studentGradient,
      seed: student.code,
      initials: student.initials,
      avatarUrl: student.avatarUrl,
      heroTag: 'student-avatar-${student.code}',
      title: student.name,
      subtitle: state.classroomByCode(student.classroomCode)?.name ?? '',
      overall: draftOverall,
      monthPicker: MonthPicker(
        month: state.period.start,
        blockFuture: true,
        onChanged: cubit.setPeriodMonth,
      ),
    );
  }

  Widget _emptyMilestones() {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: AssessmentUi.softSurface(),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.themeColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.inbox_rounded,
                size: 28, color: AppColors.themeColor),
          ),
          const SizedBox(height: 12),
          Text(
            'No milestones are assigned for this classroom. Please check Parameter Management.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------- insights column

  Widget _buildInsightsColumn(
    AssessmentsState state,
    AssessmentStudent student,
    List<AssessmentDomain> domains,
  ) {
    final current = state.studentAssessments(student.code, state.period);
    final previous =
        state.studentAssessments(student.code, state.period.previous);
    final radar = AssessmentAggregation.radarData(
      activeDomains: domains,
      currentRecords: current,
      previousRecords: previous,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AssessmentRadarChart(
          title: "Child's Progress",
          data: radar,
          currentLabel: AssessmentUi.shortMonthLabel(state.period.start),
          previousLabel:
              AssessmentUi.shortMonthLabel(state.period.previous.start),
        ),
        const SizedBox(height: 16),
        const AssessmentGuideCard(),
      ],
    );
  }

  // ------------------------------------------------------------------- save

  Future<void> _saveAll(BuildContext context, AssessmentsCubit cubit) async {
    // Only milestones with a selected score are sent (unscored are skipped).
    final ok = await cubit.saveStudentAssessments(
      studentId: widget.studentCode,
      drafts: Map<String, int>.from(_scores),
      notes: Map<String, String?>.from(_notes),
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Assessments saved.'
            : 'Failed to save assessments. Please try again.'),
        backgroundColor: ok ? AppColors.successColor : AppColors.errorColor,
      ),
    );
  }
}

class _DomainScoringCard extends StatelessWidget {
  const _DomainScoringCard({
    required this.domain,
    required this.classroomCode,
    required this.state,
    required this.scores,
    required this.notes,
    required this.domainScore,
    required this.onChanged,
    this.initiallyExpanded = false,
  });

  final AssessmentDomain domain;
  final String classroomCode;
  final AssessmentsState state;
  final Map<String, int> scores;
  final Map<String, String> notes;
  final Map<String, int> domainScore;
  final VoidCallback onChanged;
  final bool initiallyExpanded;

  /// Live average of the drafted milestone scores in this domain.
  double? _draftAverage() {
    final ms = state.milestonesForClassroom(domain, classroomCode);
    final vals = ms
        .map((m) => scores[m.id])
        .whereType<int>()
        .toList(growable: false);
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  @override
  Widget build(BuildContext context) {
    final bySubdomain = state.milestonesBySubdomain(domain, classroomCode);
    final draftAvg = _draftAverage();
    final accent = AssessmentUi.scoreAccent(draftAvg);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.22)),
      ),
      shadowColor: accent.withValues(alpha: 0.20),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.account_tree_rounded, size: 19, color: accent),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(domain.name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 14.5)),
              ),
              const SizedBox(width: 8),
              ScoreBadge(score: draftAvg, dense: true),
            ],
          ),
          subtitle: domain.description.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(domain.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ),
          children: [
            // Domain-level score + Copy to All Milestones (PRD US-SA-03).
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.themeColor.withValues(alpha: 0.055),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.themeColor.withValues(alpha: 0.14)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.tune_rounded,
                          size: 16, color: AppColors.themeColor),
                      SizedBox(width: 6),
                      Text('Domain overall score',
                          style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.themeColor)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  AssessmentScaleSelector(
                    value: domainScore[domain.id],
                    onChanged: (v) {
                      domainScore[domain.id] = v;
                      onChanged();
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.themeColor),
                      onPressed: domainScore[domain.id] == null
                          ? null
                          : () => _copyToAll(),
                      icon: const Icon(Icons.copy_all_rounded, size: 18),
                      label: const Text('Copy to All Milestones'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            for (final entry in bySubdomain.entries) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF1FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(entry.key.name,
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.themeColor)),
                  ),
                ),
              ),
              ...entry.value.map((m) => _MilestoneScoreTile(
                    milestone: m,
                    score: scores[m.id],
                    note: notes[m.id] ?? '',
                    onScore: (v) {
                      scores[m.id] = v;
                      onChanged();
                    },
                    onNote: (v) {
                      if (v.isEmpty) {
                        notes.remove(m.id);
                      } else {
                        notes[m.id] = v;
                      }
                    },
                  )),
            ],
          ],
        ),
      ),
    );
  }

  void _copyToAll() {
    final value = domainScore[domain.id];
    if (value == null) return;
    for (final m in state.milestonesForClassroom(domain, classroomCode)) {
      scores[m.id] = value;
    }
    onChanged();
  }
}

/// Gradient primary action (used for "Save All Assessments"), with a loading
/// spinner and a disabled (dimmed) state.
class _GradientPrimaryButton extends StatelessWidget {
  const _GradientPrimaryButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null && !loading;
    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Ink(
            decoration: BoxDecoration(
              gradient: AssessmentUi.brandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              height: 48,
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    else
                      Icon(icon, size: 19, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14.5)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MilestoneScoreTile extends StatefulWidget {
  const _MilestoneScoreTile({
    required this.milestone,
    required this.score,
    required this.note,
    required this.onScore,
    required this.onNote,
  });

  final AssessmentMilestone milestone;
  final int? score;
  final String note;
  final ValueChanged<int> onScore;
  final ValueChanged<String> onNote;

  @override
  State<_MilestoneScoreTile> createState() => _MilestoneScoreTileState();
}

class _MilestoneScoreTileState extends State<_MilestoneScoreTile> {
  late final TextEditingController _noteController =
      TextEditingController(text: widget.note);

  @override
  void didUpdateWidget(_MilestoneScoreTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the field in sync when "Copy to All" or a period change rewrites it.
    if (widget.note != _noteController.text &&
        widget.note != oldWidget.note) {
      _noteController.text = widget.note;
    }
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scored = widget.score != null;
    final accent = scored
        ? AssessmentUi.scaleColor(widget.score!)
        : Colors.grey.shade300;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scored ? accent.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scored ? accent.withValues(alpha: 0.45) : Colors.grey.shade200,
          width: scored ? 1.4 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) =>
                    ScaleTransition(scale: anim, child: child),
                child: Icon(
                  scored
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  key: ValueKey(scored),
                  size: 18,
                  color: scored ? accent : Colors.grey.shade400,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(widget.milestone.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (widget.milestone.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 26),
              child: Text(widget.milestone.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ),
          const SizedBox(height: 8),
          AssessmentScaleSelector(
            value: widget.score,
            onChanged: widget.onScore,
            compact: true,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteController,
            maxLength: 500,
            maxLines: 2,
            onChanged: widget.onNote,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
              isDense: true,
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }
}
