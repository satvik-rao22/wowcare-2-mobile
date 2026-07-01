import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_parameters.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_references.dart';
import 'package:wowcare/domain/features/assessments/entities/assessment_scale.dart';
import 'package:wowcare/presentation/features/assessments/cubit/assessments_cubit.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_access.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_aggregation.dart';
import 'package:wowcare/presentation/features/assessments/utils/assessment_ui_utils.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_confirm_dialog.dart';
import 'package:wowcare/presentation/features/assessments/widgets/assessment_radar_chart.dart';
import 'package:wowcare/presentation/features/assessments/widgets/scale_button_row.dart';
import 'package:wowcare/shared/common/app/cubit/role_cubit.dart';

/// In-place scoring stepper for one student in the active period (PRD §12.2).
///
/// Starts on an Overview step (radar this-vs-last period + domain summary;
/// empty until the student has any scores), then one step per
/// classroom-relevant domain — each offering a "set whole domain" quick-pick
/// with copy-to-all, and per-milestone 1–5 scoring with optional notes — and
/// ends on a Review step (same summary as Overview). The footer drives
/// Back/Next/Review/Save; saving upserts every scored milestone in a single
/// transaction via the cubit, then exits. Once every milestone is scored, a
/// Publish button (on Overview and Review) marks the assessment finalized.
class StudentStepperBody extends StatefulWidget {
  const StudentStepperBody({
    super.key,
    required this.studentCode,
    required this.onExit,
  });

  final String studentCode;
  final VoidCallback onExit;

  @override
  State<StudentStepperBody> createState() => _StudentStepperBodyState();
}

class _StudentStepperBodyState extends State<StudentStepperBody> {
  final Map<String, int> _scores = {};
  final Map<String, String> _notes = {};
  final Map<String, int> _domainDraft = {};
  final Set<String> _openNotes = {};
  int _stepIndex = 0;
  bool _seeded = false;

  void _seed(AssessmentsState state) {
    if (_seeded) return;
    _seeded = true;
    for (final a in state.studentAssessments(widget.studentCode, state.period)) {
      _scores[a.milestoneId] = a.score;
      if ((a.notes ?? '').isNotEmpty) {
        _notes[a.milestoneId] = a.notes!;
        _openNotes.add(a.milestoneId);
      }
    }
  }

  double? _overall() {
    if (_scores.isEmpty) return null;
    return _scores.values.reduce((a, b) => a + b) / _scores.length;
  }

  /// Whether every classroom-relevant milestone (across all domains) has a
  /// draft score — the "all params completed and ranked" gate for Publish.
  bool _isFullyScored(AssessmentsState state, String classroomCode) {
    final domains = state.domainsForClassroom(classroomCode);
    if (domains.isEmpty) return false;
    for (final domain in domains) {
      for (final m in state.milestonesForClassroom(domain, classroomCode)) {
        if (!_scores.containsKey(m.id)) return false;
      }
    }
    return true;
  }

  double? _domainAvg(AssessmentsState state, AssessmentDomain domain,
      String classroomCode) {
    final ids = state
        .milestonesForClassroom(domain, classroomCode)
        .map((m) => m.id);
    final vals = ids.map((id) => _scores[id]).whereType<int>().toList();
    if (vals.isEmpty) return null;
    return vals.reduce((a, b) => a + b) / vals.length;
  }

  /// Scoring progress for one domain's classroom-relevant milestones — drives
  /// the stepper's per-step state (none / partial / complete).
  ({bool any, bool all}) _domainProgress(
      AssessmentsState state, AssessmentDomain domain, String classroomCode) {
    final ms = state.milestonesForClassroom(domain, classroomCode);
    if (ms.isEmpty) return (any: false, all: false);
    final scored = ms.where((m) => _scores.containsKey(m.id)).length;
    return (any: scored > 0, all: scored == ms.length);
  }

  void _pickScore(String milestoneId, int score) {
    setState(() => _scores[milestoneId] = score);
  }

  void _pickDomain(String domainId, int score) {
    setState(() => _domainDraft[domainId] = score);
  }

  void _copyToAll(AssessmentsState state, AssessmentDomain domain,
      String classroomCode) {
    final value = _domainDraft[domain.id];
    if (value == null) {
      _toast('Pick a domain score first');
      return;
    }
    setState(() {
      for (final m in state.milestonesForClassroom(domain, classroomCode)) {
        _scores[m.id] = value;
      }
    });
    _toast('Applied to all milestones');
  }

  void _setNote(String milestoneId, String text) {
    if (text.isEmpty) {
      _notes.remove(milestoneId);
    } else {
      _notes[milestoneId] = text;
    }
  }

  void _toggleNote(String milestoneId) {
    setState(() {
      if (_openNotes.contains(milestoneId)) {
        _openNotes.remove(milestoneId);
      } else {
        _openNotes.add(milestoneId);
      }
    });
  }

  void _toast(String message) {
    // Lift the floating snackbar above the fixed footer (Back/Next/Save) so it
    // never covers the primary action button.
    final footerClearance = 96.0 + MediaQuery.of(context).padding.bottom;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AssessmentUi.ink,
        margin: EdgeInsets.fromLTRB(16, 0, 16, footerClearance),
      ));
  }

  Future<void> _save(AssessmentsCubit cubit) async {
    final ok = await cubit.saveStudentAssessments(
      studentId: widget.studentCode,
      drafts: Map<String, int>.from(_scores),
      notes: Map<String, String?>.from(_notes),
    );
    if (!mounted) return;
    if (ok) {
      _toast('All assessments saved');
      widget.onExit();
    } else {
      _toast('Failed to save. Please try again.');
    }
  }

  Future<void> _publish(AssessmentsCubit cubit) async {
    final confirmed = await AssessmentConfirmDialog.show(
      context,
      title: 'Publish assessment?',
      message: 'This marks the assessment as finalized for the period. You '
          'can still edit scores afterward.',
      confirmLabel: 'Publish',
      destructive: false,
    );
    if (!confirmed || !mounted) return;
    final saved = await cubit.saveStudentAssessments(
      studentId: widget.studentCode,
      drafts: Map<String, int>.from(_scores),
      notes: Map<String, String?>.from(_notes),
    );
    if (!saved || !mounted) return;
    final published = await cubit.publishStudentAssessments(widget.studentCode);
    if (!mounted) return;
    _toast(published ? 'Assessment published' : 'Failed to publish. Please try again.');
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AssessmentsCubit>();
    final canEnterAssessments =
        AssessmentAccess.canEnterAssessments(context.watch<RoleCubit>());
    return BlocBuilder<AssessmentsCubit, AssessmentsState>(
      builder: (context, state) {
        final student = state.studentByCode(widget.studentCode);
        if (student == null) {
          return const Center(child: Text('Student not found.'));
        }
        _seed(state);
        final domains = state.domainsForClassroom(student.classroomCode);
        final n = domains.length;
        final isOverview = _stepIndex == 0;
        final isReview = _stepIndex >= n + 1 && n > 0;
        final classroom = state.classroomByCode(student.classroomCode);
        final isPublished = state.isPublished(widget.studentCode, state.period);
        final showPublish = canEnterAssessments &&
            !isPublished &&
            _isFullyScored(state, student.classroomCode);
        final stepLabel = isOverview
            ? 'Overview'
            : isReview
                ? 'Review'
                : 'Domain $_stepIndex of $n';
        final progress = n == 0 ? 1.0 : (_stepIndex + 1) / (n + 2);

        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(0, 0, 0, 8),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _Hero(
                      student: student,
                      classroomName: classroom?.name ?? '',
                      period: state.period,
                      overall: _overall(),
                      stepLabel: stepLabel,
                      progress: progress,
                      scoredCount: _scores.length,
                      isPublished: isPublished,
                    ),
                  ),
                  if (n > 0) ...[
                    const SizedBox(height: 14),
                    _DomainStepper(
                      domains: domains,
                      stepIndex: _stepIndex - 1,
                      progressOf: (d) =>
                          _domainProgress(state, d, student.classroomCode),
                      onTap: (i) {
                        final target = i + 1;
                        if (target != _stepIndex) {
                          setState(() => _stepIndex = target);
                        }
                      },
                    ),
                  ],
                  if (n == 0)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 40, 20, 20),
                      child: Text(
                        'No milestones are assigned for this classroom. '
                        'Add them under Parameters first.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AssessmentUi.inkMuted),
                      ),
                    )
                  else if (isOverview)
                    _OverviewStep(
                      state: state,
                      student: student,
                      domains: domains,
                      draftDomainAvg: (d) =>
                          _domainAvg(state, d, student.classroomCode),
                      assessed: _scores.isNotEmpty,
                      showPublish: showPublish,
                      saving: state.isSaving,
                      onPublish: () => unawaited(_publish(cubit)),
                    )
                  else if (isReview)
                    _ReviewStep(
                      state: state,
                      student: student,
                      domains: domains,
                      draftDomainAvg: (d) =>
                          _domainAvg(state, d, student.classroomCode),
                      showPublish: showPublish,
                      saving: state.isSaving,
                      onPublish: () => unawaited(_publish(cubit)),
                    )
                  else
                    _DomainStep(
                      state: state,
                      classroomCode: student.classroomCode,
                      domain: domains[_stepIndex - 1],
                      scores: _scores,
                      notes: _notes,
                      openNotes: _openNotes,
                      domainDraft: _domainDraft[domains[_stepIndex - 1].id],
                      onPickScore: _pickScore,
                      onPickDomain: (v) =>
                          _pickDomain(domains[_stepIndex - 1].id, v),
                      onCopyToAll: () => _copyToAll(
                          state, domains[_stepIndex - 1], student.classroomCode),
                      onToggleNote: _toggleNote,
                      onNote: _setNote,
                    ),
                ],
              ),
            ),
            if (n > 0)
              _Footer(
                isFirstStep: _stepIndex == 0,
                isReview: isReview,
                nextLabel: isOverview
                    ? (_scores.isEmpty ? 'Start' : 'Next')
                    : (isReview
                        ? 'Save All Assessments'
                        : (_stepIndex < n ? 'Next' : 'Review')),
                saving: state.isSaving,
                onPrev: () {
                  if (_stepIndex == 0) {
                    widget.onExit();
                  } else {
                    setState(() => _stepIndex--);
                  }
                },
                onNext: () {
                  if (isReview) {
                    unawaited(_save(cubit));
                  } else {
                    setState(() => _stepIndex++);
                  }
                },
              ),
          ],
        );
      },
    );
  }
}

// ------------------------------------------------------------------- hero

class _Hero extends StatelessWidget {
  const _Hero({
    required this.student,
    required this.classroomName,
    required this.period,
    required this.overall,
    required this.stepLabel,
    required this.progress,
    required this.scoredCount,
    required this.isPublished,
  });

  final AssessmentStudent student;
  final String classroomName;
  final AssessmentPeriod period;
  final double? overall;
  final String stepLabel;
  final double progress;
  final int scoredCount;
  final bool isPublished;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AssessmentUi.studentGradient,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.themeColor.withValues(alpha: 0.32),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  student.initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            student.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isPublished) ...[
                          const SizedBox(width: 8),
                          const _PublishedChip(),
                        ],
                      ],
                    ),
                    Text(
                      '$classroomName · ${AssessmentUi.shortMonthLabel(period.start)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text(
                    overall == null ? '—' : overall!.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 23,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    AssessmentUi.scoreSummary(overall),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                stepLabel,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                '$scoredCount scored',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.82),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress.clamp(0, 1)),
              duration: const Duration(milliseconds: 300),
              builder: (context, v, _) => LinearProgressIndicator(
                value: v,
                minHeight: 6,
                backgroundColor: Colors.white.withValues(alpha: 0.25),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small "Published" pill shown in the [_Hero] once every record for this
/// student+period is published (PRD ask: a status chip, not a lock).
class _PublishedChip extends StatelessWidget {
  const _PublishedChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
          SizedBox(width: 4),
          Text(
            'Published',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- stepper

/// Tappable horizontal stepper letting the assessor jump freely between
/// domains (and the trailing Review step) instead of only Back/Next. Each node
/// reflects its scoring state: complete (all milestones scored → green check),
/// partial (some scored → brand ring), or untouched (grey), with the current
/// step filled. Scrolls horizontally when domains overflow the width.
class _DomainStepper extends StatelessWidget {
  const _DomainStepper({
    required this.domains,
    required this.stepIndex,
    required this.progressOf,
    required this.onTap,
  });

  final List<AssessmentDomain> domains;
  final int stepIndex;
  final ({bool any, bool all}) Function(AssessmentDomain) progressOf;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final reviewIndex = domains.length;
    final nodes = <Widget>[];
    for (var i = 0; i < domains.length; i++) {
      if (i > 0) nodes.add(const _StepConnector());
      final p = progressOf(domains[i]);
      nodes.add(_StepNode(
        index: i,
        label: domains[i].name,
        current: stepIndex == i,
        complete: p.all,
        partial: p.any && !p.all,
        onTap: () => onTap(i),
      ));
    }
    // Trailing Review step.
    nodes.add(const _StepConnector());
    nodes.add(_StepNode(
      index: reviewIndex,
      label: 'Review',
      icon: Icons.flag_rounded,
      current: stepIndex >= reviewIndex,
      complete: false,
      partial: false,
      onTap: () => onTap(reviewIndex),
    ));

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: nodes),
    );
  }
}

/// One node in [_DomainStepper] — a tappable numbered/checked circle with a
/// short label beneath it.
class _StepNode extends StatelessWidget {
  const _StepNode({
    required this.index,
    required this.label,
    required this.current,
    required this.complete,
    required this.partial,
    required this.onTap,
    this.icon,
  });

  final int index;
  final String label;
  final bool current;
  final bool complete;
  final bool partial;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A);
    final Color circleColor;
    final Color borderColor;
    final Color fgColor;
    if (current) {
      circleColor = AssessmentUi.brand;
      borderColor = AssessmentUi.brand;
      fgColor = Colors.white;
    } else if (complete) {
      circleColor = const Color(0xFFECFDF3);
      borderColor = green;
      fgColor = green;
    } else if (partial) {
      circleColor = Colors.white;
      borderColor = AssessmentUi.brand;
      fgColor = AssessmentUi.brand;
    } else {
      circleColor = Colors.white;
      borderColor = AssessmentUi.hairline;
      fgColor = AssessmentUi.inkMuted;
    }

    final Widget glyph;
    if (complete && !current) {
      glyph = Icon(Icons.check_rounded, size: 18, color: fgColor);
    } else if (icon != null) {
      glyph = Icon(icon, size: 16, color: fgColor);
    } else {
      glyph = Text(
        '${index + 1}',
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: fgColor,
        ),
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: glyph,
            ),
            const SizedBox(height: 5),
            Text(
              label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                height: 1.15,
                fontWeight: current ? FontWeight.w700 : FontWeight.w600,
                color: current ? AssessmentUi.ink : AssessmentUi.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Thin connector line between two stepper nodes (aligned to the circle row).
class _StepConnector extends StatelessWidget {
  const _StepConnector();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 2,
      margin: const EdgeInsets.only(top: 16),
      color: AssessmentUi.hairline,
    );
  }
}

// ------------------------------------------------------------- domain step

class _DomainStep extends StatelessWidget {
  const _DomainStep({
    required this.state,
    required this.classroomCode,
    required this.domain,
    required this.scores,
    required this.notes,
    required this.openNotes,
    required this.domainDraft,
    required this.onPickScore,
    required this.onPickDomain,
    required this.onCopyToAll,
    required this.onToggleNote,
    required this.onNote,
  });

  final AssessmentsState state;
  final String classroomCode;
  final AssessmentDomain domain;
  final Map<String, int> scores;
  final Map<String, String> notes;
  final Set<String> openNotes;
  final int? domainDraft;
  final void Function(String milestoneId, int score) onPickScore;
  final ValueChanged<int> onPickDomain;
  final VoidCallback onCopyToAll;
  final ValueChanged<String> onToggleNote;
  final void Function(String milestoneId, String text) onNote;

  @override
  Widget build(BuildContext context) {
    final color = AssessmentUi.domainColor(domain.id);
    final bySubdomain = state.milestonesBySubdomain(domain, classroomCode);
    final msCount = state.milestonesForClassroom(domain, classroomCode).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Container(
                  width: 13,
                  height: 13,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  domain.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AssessmentUi.ink,
                  ),
                ),
              ),
            ],
          ),
          if (domain.description.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              domain.description,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
                color: Color(0xFF8A8398),
              ),
            ),
          ],
          const SizedBox(height: 13),
          _QuickSet(
            value: domainDraft,
            milestoneCount: msCount,
            onPick: onPickDomain,
            onCopyToAll: onCopyToAll,
          ),
          const SizedBox(height: 16),
          for (final entry in bySubdomain.entries) ...[
            _SubdomainDivider(name: entry.key.name),
            ...entry.value.map((m) => _MilestoneCard(
                  milestone: m,
                  score: scores[m.id],
                  note: notes[m.id] ?? '',
                  noteOpen: openNotes.contains(m.id),
                  onScore: (v) => onPickScore(m.id, v),
                  onToggleNote: () => onToggleNote(m.id),
                  onNote: (v) => onNote(m.id, v),
                )),
          ],
          const SizedBox(height: 4),
          const _ScaleLegend(),
        ],
      ),
    );
  }
}

class _QuickSet extends StatelessWidget {
  const _QuickSet({
    required this.value,
    required this.milestoneCount,
    required this.onPick,
    required this.onCopyToAll,
  });

  final int? value;
  final int milestoneCount;
  final ValueChanged<int> onPick;
  final VoidCallback onCopyToAll;

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF1FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFDCE2FF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.add_circle_outline_rounded,
                  size: 15, color: AppColors.themeColor),
              SizedBox(width: 6),
              Text(
                'Set whole domain at once',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF3F58C9),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ScaleButtonRow(value: value, onPick: onPick),
          const SizedBox(height: 11),
          Material(
            color: hasValue ? AppColors.themeColor : const Color(0xFFE3E8FF),
            borderRadius: BorderRadius.circular(11),
            child: InkWell(
              onTap: onCopyToAll,
              borderRadius: BorderRadius.circular(11),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 9),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.copy_all_rounded,
                        size: 15,
                        color: hasValue ? Colors.white : const Color(0xFF9BA8E0)),
                    const SizedBox(width: 6),
                    Text(
                      'Copy to all $milestoneCount milestones',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color:
                            hasValue ? Colors.white : const Color(0xFF9BA8E0),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubdomainDivider extends StatelessWidget {
  const _SubdomainDivider({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Expanded(child: Divider(color: Color(0xFFE6E3F0), height: 1)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Text(
              name.toUpperCase(),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Color(0xFF8A8398),
              ),
            ),
          ),
          const Expanded(child: Divider(color: Color(0xFFE6E3F0), height: 1)),
        ],
      ),
    );
  }
}

class _MilestoneCard extends StatefulWidget {
  const _MilestoneCard({
    required this.milestone,
    required this.score,
    required this.note,
    required this.noteOpen,
    required this.onScore,
    required this.onToggleNote,
    required this.onNote,
  });

  final AssessmentMilestone milestone;
  final int? score;
  final String note;
  final bool noteOpen;
  final ValueChanged<int> onScore;
  final VoidCallback onToggleNote;
  final ValueChanged<String> onNote;

  @override
  State<_MilestoneCard> createState() => _MilestoneCardState();
}

class _MilestoneCardState extends State<_MilestoneCard> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.note);

  @override
  void didUpdateWidget(_MilestoneCard old) {
    super.didUpdateWidget(old);
    if (widget.note != _controller.text && widget.note != old.note) {
      _controller.text = widget.note;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scored = widget.score != null;
    final accent =
        scored ? AssessmentUi.scaleColor(widget.score!) : const Color(0xFFCFCAD9);
    final border = scored
        ? AssessmentUi.scaleColor(widget.score!).withValues(alpha: 0.4)
        : const Color(0xFFEFEDF5);
    return Container(
      margin: const EdgeInsets.only(bottom: 11),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2559).withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Icon(
                  scored
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: accent,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.milestone.name,
                      style: const TextStyle(
                        fontSize: 13.5,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AssessmentUi.ink,
                      ),
                    ),
                    if (widget.milestone.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          widget.milestone.description,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: AssessmentUi.inkMuted,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ScaleButtonRow(value: widget.score, onPick: widget.onScore),
          if (widget.noteOpen) ...[
            const SizedBox(height: 11),
            TextField(
              controller: _controller,
              maxLength: 500,
              maxLines: null,
              minLines: 2,
              onChanged: widget.onNote,
              style: const TextStyle(fontSize: 12.5, color: AssessmentUi.ink),
              decoration: InputDecoration(
                hintText: 'Add an observation note (optional)',
                counterText: '',
                isDense: true,
                contentPadding: const EdgeInsets.all(10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide: const BorderSide(color: Color(0xFFE6E3F0), width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(11),
                  borderSide:
                      const BorderSide(color: AppColors.themeColor, width: 1.5),
                ),
              ),
            ),
          ] else ...[
            const SizedBox(height: 9),
            InkWell(
              onTap: widget.onToggleNote,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.add_rounded, size: 15, color: AppColors.themeColor),
                  SizedBox(width: 5),
                  Text(
                    'Add note',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.themeColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScaleLegend extends StatelessWidget {
  const _ScaleLegend();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 13),
      decoration: AssessmentUi.softSurface(radius: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'ASSESSMENT SCALE',
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              color: AssessmentUi.inkMuted,
            ),
          ),
          const SizedBox(height: 9),
          ...AssessmentScale.values.map((score) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.5),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AssessmentUi.scaleColor(score),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        '$score',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Text(
                      AssessmentScale.labelFor(score),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF574F66),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- review step

class _ReviewStep extends StatelessWidget {
  const _ReviewStep({
    required this.state,
    required this.student,
    required this.domains,
    required this.draftDomainAvg,
    required this.showPublish,
    required this.saving,
    required this.onPublish,
  });

  final AssessmentsState state;
  final AssessmentStudent student;
  final List<AssessmentDomain> domains;
  final double? Function(AssessmentDomain) draftDomainAvg;
  final bool showPublish;
  final bool saving;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final previous =
        state.studentAssessments(student.code, state.period.previous);
    final radar = domains
        .map((d) => RadarDatum(
              domainId: d.id,
              domainName: _short(d.name),
              current: draftDomainAvg(d) ?? 0,
              previous: AssessmentAggregation.domainAverage(previous, d.id) ?? 0,
            ))
        .toList();
    final scored = domains
        .map(draftDomainAvg)
        .where((v) => v != null)
        .length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Review & save',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AssessmentUi.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '$scored of ${domains.length} domains scored for ${student.name}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8A8398),
            ),
          ),
          const SizedBox(height: 15),
          AssessmentRadarChart(
            title: 'Progress this month vs last',
            data: radar,
            currentLabel: AssessmentUi.shortMonthLabel(state.period.start),
            previousLabel:
                AssessmentUi.shortMonthLabel(state.period.previous.start),
          ),
          const SizedBox(height: 14),
          _DomainSummaryCard(domains: domains, draftDomainAvg: draftDomainAvg),
          if (showPublish) ...[
            const SizedBox(height: 14),
            _PublishButton(saving: saving, onTap: onPublish),
          ],
        ],
      ),
    );
  }

  static String _short(String name) => name.split(' ').first;
}

/// "Domain summary" card (name + mini progress bar + average per domain),
/// shared by [_OverviewStep] and [_ReviewStep].
class _DomainSummaryCard extends StatelessWidget {
  const _DomainSummaryCard({
    required this.domains,
    required this.draftDomainAvg,
  });

  final List<AssessmentDomain> domains;
  final double? Function(AssessmentDomain) draftDomainAvg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: AssessmentUi.softSurface(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Domain summary',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AssessmentUi.ink,
            ),
          ),
          const SizedBox(height: 11),
          ...domains.map((d) {
            final avg = draftDomainAvg(d);
            final color = AssessmentUi.scoreAccent(avg);
            return Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AssessmentUi.domainColor(d.id),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d.name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AssessmentUi.ink,
                          ),
                        ),
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: ((avg ?? 0) / 5).clamp(0, 1),
                            minHeight: 6,
                            backgroundColor: const Color(0xFFF0EEF6),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 30,
                    child: Text(
                      AssessmentAggregation.formatAverage(avg),
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

/// Green "Publish" pill shown on [_OverviewStep] and [_ReviewStep] once every
/// milestone is scored and the assessment isn't already published.
class _PublishButton extends StatelessWidget {
  const _PublishButton({required this.saving, required this.onTap});

  final bool saving;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: saving ? null : onTap,
          borderRadius: BorderRadius.circular(14),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF16A34A), Color(0xFF15803D)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.campaign_rounded,
                            size: 17, color: Colors.white),
                        SizedBox(width: 7),
                        Text(
                          'Publish',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
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

// ------------------------------------------------------------- overview step

class _OverviewStep extends StatelessWidget {
  const _OverviewStep({
    required this.state,
    required this.student,
    required this.domains,
    required this.draftDomainAvg,
    required this.assessed,
    required this.showPublish,
    required this.saving,
    required this.onPublish,
  });

  final AssessmentsState state;
  final AssessmentStudent student;
  final List<AssessmentDomain> domains;
  final double? Function(AssessmentDomain) draftDomainAvg;
  final bool assessed;
  final bool showPublish;
  final bool saving;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    final previous =
        state.studentAssessments(student.code, state.period.previous);
    final radar = domains
        .map((d) => RadarDatum(
              domainId: d.id,
              domainName: _short(d.name),
              current: draftDomainAvg(d) ?? 0,
              previous: AssessmentAggregation.domainAverage(previous, d.id) ?? 0,
            ))
        .toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overview',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AssessmentUi.ink,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            assessed
                ? 'Progress for ${student.name} this month'
                : 'Not yet assessed for '
                    '${AssessmentUi.shortMonthLabel(state.period.start)}',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF8A8398),
            ),
          ),
          const SizedBox(height: 15),
          AssessmentRadarChart(
            title: 'Progress this month vs last',
            data: radar,
            currentLabel: AssessmentUi.shortMonthLabel(state.period.start),
            previousLabel:
                AssessmentUi.shortMonthLabel(state.period.previous.start),
          ),
          if (assessed) ...[
            const SizedBox(height: 14),
            _DomainSummaryCard(domains: domains, draftDomainAvg: draftDomainAvg),
          ],
          if (showPublish) ...[
            const SizedBox(height: 14),
            _PublishButton(saving: saving, onTap: onPublish),
          ],
        ],
      ),
    );
  }

  static String _short(String name) => name.split(' ').first;
}

// ----------------------------------------------------------------- footer

class _Footer extends StatelessWidget {
  const _Footer({
    required this.isFirstStep,
    required this.isReview,
    required this.nextLabel,
    required this.saving,
    required this.onPrev,
    required this.onNext,
  });

  final bool isFirstStep;
  final bool isReview;
  final String nextLabel;
  final bool saving;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final prevLabel = isFirstStep ? 'Exit' : 'Back';
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B2559).withValues(alpha: 0.07),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Row(
        children: [
          Material(
            color: const Color(0xFFF2F0F8),
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              onTap: saving ? null : onPrev,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Text(
                  prevLabel,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF574F66),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: saving ? null : onNext,
                borderRadius: BorderRadius.circular(14),
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: isReview
                        ? const LinearGradient(
                            colors: [Color(0xFF16A34A), Color(0xFF15803D)])
                        : AssessmentUi.brandGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (saving)
                          const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        else ...[
                          if (isReview)
                            const Icon(Icons.save_rounded,
                                size: 17, color: Colors.white),
                          if (isReview) const SizedBox(width: 7),
                          Text(
                            nextLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          if (!isReview) const SizedBox(width: 7),
                          if (!isReview)
                            const Icon(Icons.arrow_forward_rounded,
                                size: 16, color: Colors.white),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
