import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/core/widgets/trough.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';

/// Today's school status (3A1): the shape of the school, then how students
/// and staff divide across the four attendance states.
///
/// Counts are written students-first, and the trough's four segments are in
/// the same order as the legend under it, so the bar and the chips can never
/// disagree about which colour means what.
class SchoolStatusCard extends StatelessWidget {
  const SchoolStatusCard({
    required this.status,
    required this.onViewAll,
    super.key,
  });

  final SchoolStatus status;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: DashboardSizes.summaryTileGap,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  DashboardStrings.schoolStatus,
                  style: AppTextStyles.cardTitle.copyWith(color: c.ink),
                ),
              ),
              TextLink(
                label: AppStrings.viewAll,
                color: c.student,
                onTap: onViewAll,
              ),
            ],
          ),
          Row(
            spacing: DashboardSizes.statusWellGap,
            children: <Widget>[
              Expanded(
                child: _Well(
                  value: '${status.classrooms}',
                  label: DashboardStrings.classrooms,
                ),
              ),
              Expanded(
                child: _Well(
                  value: '${status.capacity}',
                  label: DashboardStrings.capacity,
                ),
              ),
              Expanded(
                child: _Well(
                  value: DashboardStrings.percent(status.occupancyPercent),
                  label: DashboardStrings.fullTimeEquivalent,
                ),
              ),
            ],
          ),
          _Divider(colours: c),
          _Group(
            title: AppStrings.students,
            titleColor: c.student,
            meta: DashboardStrings.enrolledExpected(
              status.studentsEnrolled,
              status.studentsExpected,
            ),
            breakdown: status.students,
          ),
          _Divider(colours: c),
          _Group(
            title: AppStrings.staff,
            titleColor: c.staffFg,
            meta: DashboardStrings.expectedToday(status.staffExpected),
            breakdown: status.staff,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider({required this.colours});

  final Colourway colours;

  @override
  Widget build(BuildContext context) =>
      Container(height: AppSizes.hairline, color: colours.divider);
}

/// One of the three figures across the top of the card.
class _Well extends StatelessWidget {
  const _Well({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.well(c),
      padding: DashboardSizes.statusWellPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: DashboardSizes.dayTileTextGap,
        children: <Widget>[
          Text(
            value,
            style: DashboardTextStyles.statusNumber.copyWith(color: c.ink),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: DashboardTextStyles.statusLabel.copyWith(color: c.ink2),
          ),
        ],
      ),
    );
  }
}

/// Students, or Staff: a heading, a segmented trough, and four legend chips.
class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.titleColor,
    required this.meta,
    required this.breakdown,
  });

  final String title;
  final Color titleColor;
  final String meta;
  final AttendanceBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final fractions = breakdown.fractions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: DashboardSizes.statusBlockGap,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: DashboardTextStyles.statusGroupTitle.copyWith(
                  color: titleColor,
                ),
              ),
            ),
            Text(
              meta,
              style: DashboardTextStyles.statusGroupMeta.copyWith(
                color: c.ink3,
              ),
            ),
          ],
        ),
        Trough.segments(
          height: DashboardSizes.statusTroughHeight,
          segments: <TroughSegment>[
            TroughSegment(fraction: fractions[0], color: c.signedIn),
            TroughSegment(fraction: fractions[1], color: c.signedOut),
            TroughSegment(fraction: fractions[2], color: c.absent),
            TroughSegment(fraction: fractions[3], color: c.notMarked),
          ],
        ),
        Row(
          spacing: DashboardSizes.legendGap,
          children: <Widget>[
            Expanded(
              child: _Chip(
                label: AppStrings.signedIn,
                count: breakdown.signedIn,
                dot: c.signedIn,
              ),
            ),
            Expanded(
              child: _Chip(
                label: AppStrings.signedOut,
                count: breakdown.signedOut,
                dot: c.signedOut,
              ),
            ),
          ],
        ),
        Row(
          spacing: DashboardSizes.legendGap,
          children: <Widget>[
            Expanded(
              child: _Chip(
                label: AppStrings.absent,
                count: breakdown.absent,
                dot: c.absent,
              ),
            ),
            Expanded(
              child: _Chip(
                label: AppStrings.notMarked,
                count: breakdown.notMarked,
                dot: c.notMarked,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.count, required this.dot});

  final String label;
  final int count;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.altWell(c, radius: DashboardSizes.legendDot * 2),
      padding: DashboardSizes.legendChipPad,
      child: Row(
        spacing: DashboardSizes.legendGap,
        children: <Widget>[
          Container(
            width: DashboardSizes.legendDot,
            height: DashboardSizes.legendDot,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DashboardTextStyles.legendLabel.copyWith(color: c.ink2),
            ),
          ),
          Text(
            '$count',
            style: DashboardTextStyles.legendCount.copyWith(color: c.ink),
          ),
        ],
      ),
    );
  }
}
