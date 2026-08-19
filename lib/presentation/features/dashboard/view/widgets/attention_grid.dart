import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';
import 'package:wowcare/presentation/features/classrooom/views/screens/classroom_overview_screen.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/classroom_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/dashboard_attention_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/model/scheduling_models.dart';

// ── Tone ─────────────────────────────────────────────────────────────────────

enum _AttentionTone { danger, warning }

// ── Card routing types ─────────────────────────────────────────────────────────

enum _AttentionCardRoute {
  incidentApproval,
  classroomRatio,
  classroomShifts,
  pendingMovements,
  overdueMovements,
  expiredStudentDocs,
  expiringStudentDocs,
  expiredStaffDocs,
  expiringStaffDocs,
  overdueCheckups,
  studentCheckups,
}

// ── Sub-item model ────────────────────────────────────────────────────────────

/// One bullet row inside an attention card (e.g. "Overdue (3)").
class AttentionCardSubItem {
  const AttentionCardSubItem({
    required this.label,
    required this.count,
    required this.tone,
  });

  final String label;
  final int count;
  final _AttentionTone tone;
}

// ── Card model ────────────────────────────────────────────────────────────────

/// Data model for one "Need your attention" card.
class AttentionCardModel {
  const AttentionCardModel({
    required this.label,
    required this.count,
    required this.route,
    this.pillText,
    this.tone = _AttentionTone.danger,
    this.showThumbDown = false,
    this.isCurrency = false,
    this.valueText,
    this.subItems,
    this.labelTag,
  });

  final String label;

  /// Optional small tag shown next to the label (e.g. "This Month").
  final String? labelTag;

  /// The numeric count driving visibility and display.
  final int count;

  /// Shown as a pill badge when [subItems] is null and [valueText] is null.
  final String? pillText;
  final _AttentionTone tone;
  final bool showThumbDown;
  final _AttentionCardRoute route;

  /// True for the "Total Outstanding" financial card.
  final bool isCurrency;

  /// Display string for the currency card (e.g. "\$5 000 (5%)").
  final String? valueText;

  /// When non-null, shows bullet sub-item rows instead of the pill badge.
  final List<AttentionCardSubItem>? subItems;

  bool get shouldShow =>
      isCurrency ? (valueText != null && valueText!.isNotEmpty) : count > 0;
}

// ── Attention Grid ─────────────────────────────────────────────────────────────

/// "Need your attention" section.
///
/// - Reads live counts from [RatioMonitoringCubit], [ClassroomShiftsCubit],
///   and [DashboardAttentionCubit].
/// - Hides cards whose count is 0; hides the entire section when all counts are 0.
/// - Shows first 4 cards; "Show More / Show Less" expands/collapses the rest.
/// - [onRatioCardTap] / [onShiftsCardTap]: when provided, the card scrolls to the
///   target widget instead of navigating to a separate screen.
class AttentionGrid extends StatefulWidget {
  const AttentionGrid({
    super.key,
    this.onRatioCardTap,
    this.onShiftsCardTap,
    this.onIncidentCardTap,
  });

  final VoidCallback? onRatioCardTap;
  final VoidCallback? onShiftsCardTap;
  final VoidCallback? onIncidentCardTap;

  @override
  State<AttentionGrid> createState() => _AttentionGridState();
}

class _AttentionGridState extends State<AttentionGrid> {
  static const int _initialCount = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    // Flat watch — each cubit triggers exactly one rebuild of this widget,
    // not a cascade through nested builders.
    final ratioState = context.watch<RatioMonitoringCubit>().state;
    final shiftsState = context.watch<ClassroomShiftsCubit>().state;
    final attentionState = context.watch<DashboardAttentionCubit>().state;

    final isLoading =
        ratioState.isLoading ||
        shiftsState.isLoading ||
        attentionState.isLoading ||
        attentionState.isInitial;

    final cards = _buildCards(ratioState, shiftsState, attentionState);

    if (isLoading && cards.isEmpty) {
      return _buildLoadingSection();
    }

    if (cards.isEmpty) return const SizedBox.shrink();

    final initialCards = cards.take(_initialCount).toList();
    final extraCards = cards.skip(_initialCount).toList();
    final hasMore = extraCards.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need your attention',
          style: SkeuText.title(
            weight: SkeuText.weightHeading,
          ).copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        _buildGrid(initialCards, _handleCardTap),
        if (hasMore) ...[
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: _buildGrid(extraCards, _handleCardTap),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          _ShowMoreButton(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ] else
          const SizedBox(height: 4),
      ],
    );
  }

  void _handleCardTap(_AttentionCardRoute route) {
    switch (route) {
      case _AttentionCardRoute.incidentApproval:
        if (widget.onIncidentCardTap != null) {
          widget.onIncidentCardTap!();
        } else {
          context.go('/activityFeed');
        }

      case _AttentionCardRoute.classroomRatio:
        if (widget.onRatioCardTap != null) {
          widget.onRatioCardTap!();
        } else {
          context.go(ClassroomOverviewScreen.routeName);
        }

      case _AttentionCardRoute.classroomShifts:
        if (widget.onShiftsCardTap != null) {
          widget.onShiftsCardTap!();
        } else {
          context.go('/dashboard/scheduling');
        }

      case _AttentionCardRoute.pendingMovements:
      case _AttentionCardRoute.overdueMovements:
        context.go('/dashboard/individual-movement');

      // Disable navigation for Expiry & Physical Checkup cards
      case _AttentionCardRoute.expiredStudentDocs:
      case _AttentionCardRoute.expiringStudentDocs:
      case _AttentionCardRoute.expiredStaffDocs:
      case _AttentionCardRoute.expiringStaffDocs:
      case _AttentionCardRoute.overdueCheckups:
      case _AttentionCardRoute.studentCheckups:
        return;
    }
  }

  Widget _buildGrid(
    List<AttentionCardModel> cards,
    Function(_AttentionCardRoute) onCardTap,
  ) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      final hasRight = i + 1 < cards.length;
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _AttentionCard(
                  model: cards[i],
                  onTap: () => onCardTap(cards[i].route),
                ),
              ),
              const SizedBox(width: 12),
              // Invisible placeholder keeps left card from stretching full width
              // when the row has an odd card.
              Expanded(
                child: hasRight
                    ? _AttentionCard(
                        model: cards[i + 1],
                        onTap: () => onCardTap(cards[i + 1].route),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: rows);
  }

  Widget _buildLoadingSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Need your attention',
          style: SkeuText.title(
            weight: SkeuText.weightHeading,
          ).copyWith(fontSize: 18),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _ShimmerCard()),
              const SizedBox(width: 12),
              Expanded(child: _ShimmerCard()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _ShimmerCard()),
              const SizedBox(width: 12),
              Expanded(child: _ShimmerCard()),
            ],
          ),
        ),
      ],
    );
  }

  List<AttentionCardModel> _buildCards(
    RatioMonitoringState ratioState,
    ClassroomShiftsState shiftsState,
    DashboardAttentionState attentionState,
  ) {
    final classroomCount = ratioState.isLoaded
        ? ratioState.classrooms.where((c) => !c.isRatioGood).length
        : 0;

    final shiftsCount = shiftsState.isLoaded
        ? shiftsState.entries
              .where((e) => e.ratioStatus == ClassroomRatioStatus.underRatio)
              .length
        : 0;

    return [
      // Incidents — single count, pill badge
      AttentionCardModel(
        label: 'Incidents',
        count: attentionState.pendingIncidents,
        pillText: 'Pending Approval',
        tone: _AttentionTone.warning,
        route: _AttentionCardRoute.incidentApproval,
      ),
      // Classrooms — single count, pill badge
      AttentionCardModel(
        label: 'Classrooms',
        count: classroomCount,
        pillText: 'Not in Ratio',
        tone: _AttentionTone.danger,
        showThumbDown: true,
        route: _AttentionCardRoute.classroomRatio,
      ),
      // Classroom Shifts — single count, pill badge
      AttentionCardModel(
        label: 'Classroom Shifts',
        count: shiftsCount,
        pillText: 'Need Attention',
        tone: _AttentionTone.danger,
        route: _AttentionCardRoute.classroomShifts,
      ),
      // Movement — consolidated with sub-items
      AttentionCardModel(
        label: 'Movement',
        labelTag: 'This Month',
        count:
            attentionState.overdueMovements + attentionState.pendingMovements,
        route: _AttentionCardRoute.pendingMovements,
        subItems: [
          AttentionCardSubItem(
            label: 'Overdue',
            count: attentionState.overdueMovements,
            tone: _AttentionTone.danger,
          ),
          AttentionCardSubItem(
            label: 'Pending Confirmation',
            count: attentionState.pendingMovements,
            tone: _AttentionTone.warning,
          ),
        ],
      ),
      // Student Documents — consolidated with sub-items
      AttentionCardModel(
        label: 'Student Documents',
        count:
            attentionState.expiredStudentDocuments +
            attentionState.expiringStudentDocuments,
        route: _AttentionCardRoute.expiredStudentDocs,
        subItems: [
          AttentionCardSubItem(
            label: 'Expired',
            count: attentionState.expiredStudentDocuments,
            tone: _AttentionTone.danger,
          ),
          AttentionCardSubItem(
            label: 'Expiring Soon',
            count: attentionState.expiringStudentDocuments,
            tone: _AttentionTone.warning,
          ),
        ],
      ),
      // Staff Documents — consolidated with sub-items
      AttentionCardModel(
        label: 'Staff Documents',
        count:
            attentionState.expiredDocuments + attentionState.expiringDocuments,
        route: _AttentionCardRoute.expiredStaffDocs,
        subItems: [
          AttentionCardSubItem(
            label: 'Expired',
            count: attentionState.expiredDocuments,
            tone: _AttentionTone.danger,
          ),
          AttentionCardSubItem(
            label: 'Expiring Soon',
            count: attentionState.expiringDocuments,
            tone: _AttentionTone.warning,
          ),
        ],
      ),
      // Student Physical Checkups — consolidated with sub-items
      AttentionCardModel(
        label: 'Student Physical Checkups',
        count:
            attentionState.overdueStudentCheckups +
            attentionState.missingStudentCheckups,
        route: _AttentionCardRoute.studentCheckups,
        subItems: [
          AttentionCardSubItem(
            label: 'Overdue',
            count: attentionState.overdueStudentCheckups,
            tone: _AttentionTone.danger,
          ),
          AttentionCardSubItem(
            label: 'Not Added',
            count: attentionState.missingStudentCheckups,
            tone: _AttentionTone.warning,
          ),
        ],
      ),
      // Staff Physical Checkups — consolidated with sub-items
      AttentionCardModel(
        label: 'Staff Physical Checkups',
        count: attentionState.overdueCheckups + attentionState.missingCheckups,
        route: _AttentionCardRoute.overdueCheckups,
        subItems: [
          AttentionCardSubItem(
            label: 'Overdue',
            count: attentionState.overdueCheckups,
            tone: _AttentionTone.danger,
          ),
          AttentionCardSubItem(
            label: 'Not Added',
            count: attentionState.missingCheckups,
            tone: _AttentionTone.warning,
          ),
        ],
      ),
    ].where((c) => c.shouldShow).toList();
  }
}

// ── Show More/Less button ─────────────────────────────────────────────────────

/// The "Show More / Show Less" toggle. A quiet text action, not a key: it
/// reveals more of the same content rather than performing anything.
class _ShowMoreButton extends StatelessWidget {
  const _ShowMoreButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SkeuTextButton(
      label: expanded ? 'Show Less' : 'Show More',
      onPressed: onTap,
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────

/// A card-shaped placeholder while the counts load: the real raised panel with
/// recessed blanks where the figure and label will land, so the layout does not
/// jump when the data arrives.
class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SkeuPanel(
      radius: 18,
      padding: const EdgeInsets.all(14),
      child: Shimmer.fromColors(
        baseColor: SkeuColors.cream200,
        highlightColor: SkeuColors.cream100,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SkeuColors.cream200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: SkeuColors.cream200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: 100,
              height: 24,
              decoration: BoxDecoration(
                color: SkeuColors.cream200,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Attention card ────────────────────────────────────────────────────────────

/// One "Need your attention" tile: a big teal figure, what it counts, and
/// either a status badge or a dotted breakdown underneath.
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.model, this.onTap});

  final AttentionCardModel model;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SkeuPanel(
      radius: 18,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Header row: count + label (+ optional tag) ──────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (model.isCurrency)
                _CurrencyBadge()
              else
                Text(
                  '${model.count}',
                  style: TextStyle(
                    fontFamily: SkeuText.family,
                    color: SkeuColors.teal600,
                    fontSize: 26,
                    height: 1,
                    fontWeight: SkeuText.weightBold,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: model.label,
                    style: SkeuText.body(
                      weight: SkeuText.weightHeading,
                    ).copyWith(height: 1.25),
                    children: model.labelTag == null
                        ? null
                        : [
                            TextSpan(
                              text: ' (${model.labelTag})',
                              style: SkeuText.meta(
                                color: SkeuColors.ink.withValues(alpha: .55),
                              ),
                            ),
                          ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // ── Bottom section: sub-items, value text, or pill ───────────────
          if (model.subItems != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: model.subItems!
                  .map((item) => _SubItemRow(item: item))
                  .toList(),
            )
          else if (model.valueText != null)
            Text(
              model.valueText!,
              style: TextStyle(
                fontFamily: SkeuText.family,
                color: SkeuColors.danger600,
                fontSize: 18,
                fontWeight: SkeuText.weightBold,
              ),
            )
          else
            _StatusPill(
              text: model.pillText ?? '',
              tone: model.tone,
              showThumbDown: model.showThumbDown,
            ),
        ],
      ),
    );
  }
}

// ── Currency badge ────────────────────────────────────────────────────────────

/// The outstanding-balance card leads with a currency glyph instead of a count.
class _CurrencyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SkeuIconTile(
      icon: Icons.attach_money_rounded,
      tone: SkeuTone.bad,
      size: 34,
      iconSize: 20,
      radius: 11,
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────

/// The state word under a count — "Pending Approval", "Not in Ratio". Squared
/// corners, because it labels a figure rather than ending a row.
class _StatusPill extends StatelessWidget {
  const _StatusPill({
    required this.text,
    required this.tone,
    this.showThumbDown = false,
  });

  final String text;
  final _AttentionTone tone;
  final bool showThumbDown;

  @override
  Widget build(BuildContext context) {
    return SkeuStatusChip(
      label: text,
      tone: tone == _AttentionTone.warning ? SkeuTone.warn : SkeuTone.bad,
      pill: false,
      fontSize: 12,
      icon: showThumbDown ? Icons.thumb_down_alt_outlined : null,
    );
  }
}

// ── Sub-item row ──────────────────────────────────────────────────────────────

/// One dotted breakdown line, e.g. "Overdue (3)".
class _SubItemRow extends StatelessWidget {
  const _SubItemRow({required this.item});

  final AttentionCardSubItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: SkeuLegendEntry(
        label: '${item.label} (${item.count})',
        color: item.tone == _AttentionTone.danger
            ? SkeuColors.danger500
            : SkeuColors.sun400,
      ),
    );
  }
}
