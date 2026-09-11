import 'package:flutter/material.dart';
import 'package:wowcare/core/router/app_routes.dart';
import 'package:wowcare/presentation/features/scheduling/view/scheduling_screen.dart';
import 'package:wowcare/presentation/features/availability/view/individual_movement_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/presentation/features/classroom/view/screens/classroom_overview_screen.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/classroom_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/dashboard_attention_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/view_model/ratio_monitoring_cubit.dart';
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
        const Text(
          'Need your attention',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
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
          context.go(ShellBranchRoutes.activityFeed);
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
          context.go(SchedulingScreen.routeName);
        }

      case _AttentionCardRoute.pendingMovements:
      case _AttentionCardRoute.overdueMovements:
        context.go(IndividualMovementScreen.routeName);

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
        const Text(
          'Need your attention',
          style: TextStyle(
            color: AppColors.primaryColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _AttentionShimmerCard()),
              const SizedBox(width: 12),
              Expanded(child: _AttentionShimmerCard()),
            ],
          ),
        ),
        const SizedBox(height: 12),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _AttentionShimmerCard()),
              const SizedBox(width: 12),
              Expanded(child: _AttentionShimmerCard()),
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

class _ShowMoreButton extends StatelessWidget {
  const _ShowMoreButton({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              expanded ? 'Show Less' : 'Show More',
              style: const TextStyle(
                color: AppColors.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            Icon(
              expanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
              color: AppColors.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Shimmer placeholder ───────────────────────────────────────────────────────

class _AttentionShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 80,
                  height: 14,
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                color: Colors.white,
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

class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.model, this.onTap});

  final AttentionCardModel model;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.cardBorderColor),
          borderRadius: BorderRadius.circular(10),
        ),
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
                    style: const TextStyle(
                      color: AppColors.themeColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: model.labelTag != null
                      ? Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: model.label,
                                style: const TextStyle(
                                  color: AppColors.primaryColor,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              TextSpan(
                                text: ' (${model.labelTag})',
                                style: TextStyle(
                                  color: AppColors.primaryColor.withValues(
                                    alpha: 0.55,
                                  ),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        )
                      : Text(
                          model.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primaryColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
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
                style: const TextStyle(
                  color: AppColors.themeColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
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
      ),
    );
  }
}

// ── Currency badge ────────────────────────────────────────────────────────────

class _CurrencyBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.errorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        '\$',
        style: TextStyle(
          color: AppColors.errorColor,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Status pill ───────────────────────────────────────────────────────────────

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
    final Color base = tone == _AttentionTone.warning
        ? AppColors.accentColor
        : AppColors.errorColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: base.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: base,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (showThumbDown) ...[
            const SizedBox(width: 6),
            SvgPicture.asset(MediaRes.thumbDown, width: 14, height: 14),
          ],
        ],
      ),
    );
  }
}

// ── Sub-item row ──────────────────────────────────────────────────────────────

class _SubItemRow extends StatelessWidget {
  const _SubItemRow({required this.item});

  final AttentionCardSubItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.tone == _AttentionTone.danger
        ? AppColors.errorColor
        : AppColors.accentColor;

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${item.label} (${item.count})',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.primaryColor.withValues(alpha: 0.8),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
