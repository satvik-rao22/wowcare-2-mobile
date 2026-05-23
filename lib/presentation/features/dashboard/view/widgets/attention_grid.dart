import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:wowcare/app/theme/colors.dart';
import 'package:wowcare/app/theme/media_res.dart';

/// Colour treatment for an attention card's status pill.
enum _AttentionTone { danger, warning }

/// One stat shown in the "Need your attention" grid.
class _AttentionStat {
  const _AttentionStat({
    required this.label,
    this.number,
    this.isCurrency = false,
    this.pillText,
    this.tone = _AttentionTone.danger,
    this.showThumbDown = false,
    this.valueText,
  });

  /// Big leading number, e.g. "3". Null for the currency card.
  final String? number;

  /// Renders a "$" icon box instead of [number].
  final bool isCurrency;

  final String label;

  /// Status pill text (e.g. "Not in Ratio"). Null for the currency card.
  final String? pillText;
  final _AttentionTone tone;
  final bool showThumbDown;

  /// Big value line for the currency card, e.g. "\$5000 (5%)".
  final String? valueText;
}

/// "Need your attention" 2x2 grid of summary stat cards.
///
/// UI-only: the four stats are hardcoded mock data.
class AttentionGrid extends StatelessWidget {
  const AttentionGrid({super.key});

  static const List<_AttentionStat> _stats = [
    _AttentionStat(
      number: '3',
      label: 'Classrooms',
      pillText: 'Not in Ratio',
      showThumbDown: true,
    ),
    _AttentionStat(
      number: '2',
      label: 'Classroom Shifts',
      pillText: 'Need Attention',
    ),
    _AttentionStat(
      number: '3',
      label: 'Incidents',
      pillText: 'Pending Approval',
      tone: _AttentionTone.warning,
    ),
    _AttentionStat(
      isCurrency: true,
      label: 'Total Outstanding',
      valueText: '\$5000 (5%)',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Two rows of two equal-height cards.
        for (int row = 0; row < _stats.length; row += 2) ...[
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _AttentionCard(stat: _stats[row])),
                const SizedBox(width: 12),
                Expanded(
                  child: row + 1 < _stats.length
                      ? _AttentionCard(stat: _stats[row + 1])
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          if (row + 2 < _stats.length) const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        // Show-more affordance (UI-only — no-op).
        InkWell(
          onTap: () {},
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Show More',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.primaryColor,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A single card in the [AttentionGrid].
class _AttentionCard extends StatelessWidget {
  const _AttentionCard({required this.stat});

  final _AttentionStat stat;

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
          // Leading number / "$" box + label.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (stat.isCurrency)
                _CurrencyBadge()
              else
                Text(
                  stat.number ?? '',
                  style: const TextStyle(
                    color: AppColors.themeColor,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  stat.label,
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
          // Status pill, or the big currency value line.
          if (stat.valueText != null)
            Text(
              stat.valueText!,
              style: const TextStyle(
                color: AppColors.themeColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            )
          else if (stat.pillText != null)
            _StatusPill(
              text: stat.pillText!,
              tone: stat.tone,
              showThumbDown: stat.showThumbDown,
            ),
        ],
      ),
    );
  }
}

/// Pink rounded "$" badge used by the currency card.
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

/// Coloured status pill (danger / warning tones).
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
