import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/core/widgets/text_link.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_strings.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';
import 'package:wowcare/redesign/features/dashboard/models/models.dart';

/// An attendance record over a range: a Staff member's own (3S2), or a
/// student's as their guardian sees it (3P2).
///
/// The same card both times, because the question is the same one: how many
/// days, how many hours, how many missed.
class AttendanceRecordCard extends StatelessWidget {
  const AttendanceRecordCard({
    required this.title,
    required this.record,
    required this.onChangeRange,
    this.presentLabel = DashboardStrings.daysAttended,
    super.key,
  });

  final String title;
  final AttendanceRecord record;
  final VoidCallback onChangeRange;

  /// "Days attended" for a staff member, "Days present" for a student.
  final String presentLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: DashboardSizes.summaryTileGap,
        children: <Widget>[
          Text(title, style: AppTextStyles.cardTitle.copyWith(color: c.ink)),
          SurfaceBox(
            surface: AppSurfaces.well(c),
            padding: DashboardSizes.rangeWellPad,
            child: Row(
              spacing: DashboardSizes.rangeWellGap,
              children: <Widget>[
                Icon(
                  AppIcons.calendar,
                  size: DashboardSizes.rangeWellGlyph,
                  color: c.ink3,
                ),
                Expanded(
                  child: Text(
                    record.rangeLabel,
                    style: DashboardTextStyles.rangeWellText.copyWith(
                      color: c.ink,
                    ),
                  ),
                ),
                TextLink(
                  label: DashboardStrings.change,
                  onTap: onChangeRange,
                  style: DashboardTextStyles.rangeWellLink,
                ),
              ],
            ),
          ),
          Row(
            spacing: DashboardSizes.summaryTileGap,
            children: <Widget>[
              Expanded(
                child: _Tile(
                  value: '${record.daysAttended}',
                  label: presentLabel,
                ),
              ),
              Expanded(
                child: _Tile(
                  value: record.minutesAttended == 0
                      ? DashboardStrings.hoursOnly(record.hoursAttended)
                      : DashboardStrings.hoursMinutes(
                          record.hoursAttended,
                          record.minutesAttended,
                        ),
                  label: DashboardStrings.hoursAttended,
                ),
              ),
              Expanded(
                child: _Tile(
                  value: '${record.daysAbsent}',
                  label: DashboardStrings.daysAbsent(record.daysAbsent),
                ),
              ),
            ],
          ),
          for (final day in record.days) _Day(day: day),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return SurfaceBox(
      surface: AppSurfaces.well(c),
      padding: DashboardSizes.summaryTilePad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AppSizes.space1,
        children: <Widget>[
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: DashboardTextStyles.summaryTileNumber.copyWith(
                color: c.ink,
              ),
            ),
          ),
          Text(
            label,
            maxLines: 2,
            style: DashboardTextStyles.summaryTileLabel.copyWith(
              color: c.ink2,
            ),
          ),
        ],
      ),
    );
  }
}

class _Day extends StatelessWidget {
  const _Day({required this.day});

  final AttendanceDay day;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final value = day.isAbsent
        ? (day.absenceReason!.isEmpty
              ? DashboardStrings.daysAbsent(1)
              : DashboardStrings.absentReason(day.absenceReason!))
        : DashboardStrings.arrow(day.from ?? '', day.to ?? '');

    return SurfaceBox(
      surface: AppSurfaces.altWell(c),
      padding: DashboardSizes.dayRowPad,
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              day.label,
              style: DashboardTextStyles.dayRowText.copyWith(color: c.ink),
            ),
          ),
          Text(
            value,
            style: DashboardTextStyles.dayRowText.copyWith(
              color: day.isAbsent ? c.dangerFg : c.ink2,
            ),
          ),
        ],
      ),
    );
  }
}
