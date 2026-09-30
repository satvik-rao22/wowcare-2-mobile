import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import '../../core/theme/av2_colors.dart';
import '../../core/theme/av2_spacing.dart';
import '../../core/theme/av2_text_styles.dart';
import '../../core/utils/av2_duration_formatter.dart';
import '../../domain/entities/staff_overtime_profile.dart';
import 'av2_metric_tile.dart';
import 'av2_needs_attention_banner.dart';
import 'av2_split_bar.dart';

/// The summary card: total attended time, regular/overtime split bar +
/// legend, the metric trio, and an optional needs-attention banner.
///
/// Adapts internally: stacks on narrow widths, lays the bar beside the big
/// number on wide widths.
class Av2HeroCard extends StatelessWidget {
  const Av2HeroCard({
    super.key,
    required this.profile,
    required this.periodLabel,
    required this.onPickRange,
    required this.onTapNeedsAttention,
  });

  final StaffOvertimeProfile profile;
  final String periodLabel;
  final VoidCallback onPickRange;
  final VoidCallback onTapNeedsAttention;

  @override
  Widget build(BuildContext context) {
    final agg = profile.aggregation;
    return Container(
      padding: const EdgeInsets.all(Av2Spacing.md),
      decoration: AppSurfaces.card(radius: Av2Spacing.radiusLg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _topRow(),
          const SizedBox(height: Av2Spacing.sm),
          LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 460;
              return wide ? _wideBody(agg) : _narrowBody(agg);
            },
          ),
          const SizedBox(height: Av2Spacing.sm),
          _metricTrio(agg),
          if (profile.needsAttentionCount > 0) ...[
            const SizedBox(height: Av2Spacing.sm),
            Av2NeedsAttentionBanner(
              count: profile.needsAttentionCount,
              onTap: onTapNeedsAttention,
            ),
          ],
        ],
      ),
    );
  }

  Widget _topRow() {
    return Row(
      children: [
        _rangeChip(),
        const Spacer(),
        Flexible(
          child: Text(
            'Regular ${Av2DurationFormatter.hoursLabel(profile.dailyRegularMinutes)} / day',
            style: Av2Text.label,
            textAlign: TextAlign.end,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _rangeChip() {
    return Material(
      color: Av2Colors.surfaceMuted,
      borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
      child: InkWell(
        onTap: onPickRange,
        borderRadius: BorderRadius.circular(Av2Spacing.radiusSm),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 14,
                color: Av2Colors.textSecondary,
              ),
              const SizedBox(width: 6),
              Text(
                periodLabel,
                style: Av2Text.label.copyWith(color: Av2Colors.textPrimary),
              ),
              const SizedBox(width: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                size: 15,
                color: Av2Colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _attendedBlock(OvertimeAggregation agg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          Av2DurationFormatter.hm(agg.totalAttendedMinutes),
          style: Av2Text.hero,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Text('Attended time', style: Av2Text.label),
      ],
    );
  }

  Widget _barAndLegend(OvertimeAggregation agg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Av2SplitBar(regularFraction: agg.regularFraction, height: 14),
        const SizedBox(height: Av2Spacing.xs),
        Wrap(
          spacing: Av2Spacing.md,
          runSpacing: 4,
          children: [
            Av2LegendItem(
              color: Av2Colors.barRegular,
              text:
                  'Regular (${Av2DurationFormatter.hm(agg.totalRegularMinutes)})',
              textStyle: Av2Text.caption.copyWith(color: Av2Colors.textPrimary),
            ),
            Av2LegendItem(
              color: Av2Colors.barOvertime,
              text:
                  'Overtime (${Av2DurationFormatter.hm(agg.totalOvertimeMinutes)})',
              textStyle: Av2Text.caption.copyWith(color: Av2Colors.overtime),
            ),
          ],
        ),
      ],
    );
  }

  Widget _narrowBody(OvertimeAggregation agg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _attendedBlock(agg),
        const SizedBox(height: Av2Spacing.sm),
        _barAndLegend(agg),
      ],
    );
  }

  Widget _wideBody(OvertimeAggregation agg) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 120),
          child: _attendedBlock(agg),
        ),
        const SizedBox(width: Av2Spacing.lg),
        Expanded(child: _barAndLegend(agg)),
      ],
    );
  }

  Widget _metricTrio(OvertimeAggregation agg) {
    return Row(
      children: [
        Expanded(
          child: Av2MetricTile(
            label: 'Attended',
            value: '${agg.attendedDays}',
            suffix: 'days',
          ),
        ),
        const SizedBox(width: Av2Spacing.xs),
        Expanded(
          child: Av2MetricTile(
            label: 'Absent',
            value: '${agg.absentDays}',
            suffix: 'days',
          ),
        ),
        const SizedBox(width: Av2Spacing.xs),
        Expanded(
          child: Av2MetricTile(
            label: 'Avg / day',
            value: Av2DurationFormatter.hm(agg.averageMinutesPerDay),
          ),
        ),
      ],
    );
  }
}
