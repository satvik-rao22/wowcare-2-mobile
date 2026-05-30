import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/classroom_shifts_cubit.dart';
import 'package:wowcare/presentation/features/dashboard/cubit/ratio_monitoring_cubit.dart';
import 'package:wowcare/presentation/features/scheduling/model/scheduling_models.dart';

// ── Tone ─────────────────────────────────────────────────────────────────────

enum _AttentionTone { danger, warning }

// ── Card model ────────────────────────────────────────────────────────────────

/// Data model for one "Need your attention" card.
class AttentionCardModel {
  const AttentionCardModel({
    required this.label,
    required this.count,
    required this.pillText,
    this.tone = _AttentionTone.danger,
    this.showThumbDown = false,
    this.isCurrency = false,
    this.valueText,
  });

  final String label;

  /// The numeric count driving visibility and display. Cards with [count] == 0
  /// are hidden (unless [isCurrency] is true and [valueText] is non-empty).
  final int count;

  final String pillText;
  final _AttentionTone tone;
  final bool showThumbDown;

  /// True for the "Total Outstanding" financial card.
  final bool isCurrency;

  /// Display string for the currency card (e.g. "\$5 000 (5%)").
  final String? valueText;

  /// Whether the card should render. Currency cards show when [valueText] is
  /// non-empty; all other cards show when [count] > 0.
  bool get shouldShow =>
      isCurrency ? (valueText != null && valueText!.isNotEmpty) : count > 0;
}

// ── Attention Grid ─────────────────────────────────────────────────────────────

/// "Need your attention" section.
///
/// - Reads live classroom and shifts counts from their cubits.
/// - Hides cards whose count is 0.
/// - Hides the entire section when no cards need attention.
/// - Shows first 4 cards; "Show More / Show Less" expands/collapses the rest.
class AttentionGrid extends StatefulWidget {
  const AttentionGrid({super.key});

  @override
  State<AttentionGrid> createState() => _AttentionGridState();
}

class _AttentionGridState extends State<AttentionGrid> {
  static const int _initialCount = 4;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RatioMonitoringCubit, RatioMonitoringState>(
      builder: (context, ratioState) {
        return BlocBuilder<ClassroomShiftsCubit, ClassroomShiftsState>(
          builder: (context, shiftsState) {
            final isLoading = ratioState.isLoading || shiftsState.isLoading;

            // Build the card list from live data.
            final cards = _buildCards(ratioState, shiftsState);

            // While loading, show the section with shimmer placeholders.
            if (isLoading && cards.isEmpty) {
              return _buildLoadingSection();
            }

            // All cards hidden → hide the entire section.
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

                // Always-visible first 4 cards.
                _buildGrid(initialCards),

                // Animated extra cards.
                if (hasMore) ...[
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    child: _expanded
                        ? Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: _buildGrid(extraCards),
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
          },
        );
      },
    );
  }

  /// Renders the cards list as a 2-column grid with equal-height rows.
  Widget _buildGrid(List<AttentionCardModel> cards) {
    final rows = <Widget>[];
    for (var i = 0; i < cards.length; i += 2) {
      if (i > 0) rows.add(const SizedBox(height: 12));
      rows.add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _AttentionCard(model: cards[i])),
              const SizedBox(width: 12),
              Expanded(
                child: i + 1 < cards.length
                    ? _AttentionCard(model: cards[i + 1])
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows,
    );
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

  /// Builds the filtered, visibility-checked card list from cubit states.
  ///
  /// Classroom count  → classrooms where `isRatioGood == false` (live attendance).
  /// Shifts count     → entries where `ratioStatus == underRatio` (forecast).
  /// Other categories → count 0 until their APIs are wired; cards stay hidden.
  List<AttentionCardModel> _buildCards(
    RatioMonitoringState ratioState,
    ClassroomShiftsState shiftsState,
  ) {
    final classroomCount = ratioState.isLoaded
        ? ratioState.classrooms.where((c) => !c.isRatioGood).length
        : 0;

    final shiftsCount = shiftsState.isLoaded
        ? shiftsState.entries
            .where((e) => e.ratioStatus == ClassroomRatioStatus.underRatio)
            .length
        : 0;

    const allCards = [
      // These two are wired to live cubits.
      _CardSpec(
        label: 'Classrooms',
        pillText: 'Not in Ratio',
        tone: _AttentionTone.danger,
        showThumbDown: true,
        key: _CardKey.classrooms,
      ),
      _CardSpec(
        label: 'Classroom Shifts',
        pillText: 'Need Attention',
        tone: _AttentionTone.danger,
        key: _CardKey.classroomShifts,
      ),
      // Placeholder cards — count stays 0 until APIs are integrated.
      _CardSpec(
        label: 'Incidents',
        pillText: 'Pending Approval',
        tone: _AttentionTone.warning,
        key: _CardKey.incidents,
      ),
      _CardSpec(
        label: 'Movement',
        pillText: 'Needs Review',
        tone: _AttentionTone.warning,
        key: _CardKey.movement,
      ),
      _CardSpec(
        label: 'Documents',
        pillText: 'Overdue',
        tone: _AttentionTone.danger,
        key: _CardKey.documents,
      ),
      _CardSpec(
        label: 'Physical Checkups',
        pillText: 'Overdue',
        tone: _AttentionTone.danger,
        key: _CardKey.physicalCheckups,
      ),
    ];

    int countFor(_CardSpec spec) {
      switch (spec.key) {
        case _CardKey.classrooms:
          return classroomCount;
        case _CardKey.classroomShifts:
          return shiftsCount;
        default:
          return 0;
      }
    }

    return [
      for (final spec in allCards)
        AttentionCardModel(
          label: spec.label,
          count: countFor(spec),
          pillText: spec.pillText,
          tone: spec.tone,
          showThumbDown: spec.showThumbDown,
        ),
    ].where((c) => c.shouldShow).toList();
  }
}

// ── Internal config types ─────────────────────────────────────────────────────

enum _CardKey {
  classrooms,
  classroomShifts,
  incidents,
  movement,
  documents,
  physicalCheckups,
}

class _CardSpec {
  const _CardSpec({
    required this.label,
    required this.pillText,
    required this.key,
    this.tone = _AttentionTone.danger,
    this.showThumbDown = false,
  });

  final String label;
  final String pillText;
  final _AttentionTone tone;
  final bool showThumbDown;
  final _CardKey key;
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

class _ShimmerCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
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
  const _AttentionCard({required this.model});

  final AttentionCardModel model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.cardBorderColor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
                child: Text(
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
          if (model.valueText != null)
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
              text: model.pillText,
              tone: model.tone,
              showThumbDown: model.showThumbDown,
            ),
        ],
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
