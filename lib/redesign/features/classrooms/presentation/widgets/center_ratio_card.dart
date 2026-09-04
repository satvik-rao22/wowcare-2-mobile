import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/impact_card.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// The rest of the school, read from inside one classroom (7f): the places,
/// the full time equivalent, and every classroom's ratio in one table.
///
/// The one navy surface on the record, and the only place the design tints on
/// top of the impact ground.
class CenterRatioCard extends StatelessWidget {
  const CenterRatioCard({required this.center, super.key});

  final CenterSummary center;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return ImpactCard(
      padding: ClassroomsSizes.profileCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.centerCardGap,
        children: <Widget>[
          SectionEyebrow(
            label: ClassroomsStrings.acrossTheCenter,
            color: c.onImpactSoft,
            trailing: Flexible(
              child: Text(
                ClassroomsStrings.classroomCount(center.classroomCount),
                style: ClassroomsTextStyles.cardMeta.copyWith(
                  color: c.onImpactSub,
                ),
                textAlign: TextAlign.end,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Row(
            spacing: ClassroomsSizes.statTileGap,
            children: <Widget>[
              Expanded(
                child: _ImpactTile(
                  value: '${center.totalPlaces}',
                  label: ClassroomsStrings.totalPlaces,
                ),
              ),
              Expanded(
                child: _ImpactTile(
                  value: center.fullTimeEquivalent.toStringAsFixed(1),
                  label: ClassroomsStrings.fullTimeEquivalent,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: ClassroomsSizes.centerTableGap,
            children: <Widget>[
              _headings(c),
              for (final row in center.rows) _TableRow(row: row),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headings(Colourway c) {
    final style = ClassroomsTextStyles.tableHeading.copyWith(
      color: c.onImpactSoft,
    );

    return Padding(
      padding: ClassroomsSizes.centerHeaderPad,
      child: Row(
        spacing: ClassroomsSizes.centerRowGap,
        children: <Widget>[
          Expanded(
            child: Text(ClassroomsStrings.columnClassroom, style: style),
          ),
          SizedBox(
            width: ClassroomsSizes.centerColumnCount,
            child: Text(
              ClassroomsStrings.columnIn,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: ClassroomsSizes.centerColumnCount,
            child: Text(
              ClassroomsStrings.columnStaff,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: ClassroomsSizes.centerColumnRatio,
            child: Text(
              ClassroomsStrings.columnRatio,
              style: style,
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }
}

/// A figure recessed into the navy card.
class _ImpactTile extends StatelessWidget {
  const _ImpactTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Container(
      padding: ClassroomsSizes.statTilePad,
      decoration: BoxDecoration(
        color: c.impactShadow,
        borderRadius: AppRadii.innerR,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: ClassroomsSizes.statTileTextGap,
        children: <Widget>[
          Text(
            value,
            style: ClassroomsTextStyles.statValue.copyWith(color: c.onImpact),
          ),
          Text(
            label,
            style: ClassroomsTextStyles.statLabel.copyWith(
              color: c.onImpactSoft,
            ),
          ),
        ],
      ),
    );
  }
}

/// One classroom's line in the table: counts, then a two-state pill.
class _TableRow extends StatelessWidget {
  const _TableRow({required this.row});

  final CenterRatioRow row;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Container(
      padding: ClassroomsSizes.centerRowPad,
      decoration: BoxDecoration(
        color: c.onImpact.withValues(alpha: ClassroomsSizes.onImpactRowAlpha),
        borderRadius: AppRadii.innerR,
      ),
      child: Row(
        spacing: ClassroomsSizes.centerRowGap,
        children: <Widget>[
          Expanded(
            child: Text(
              row.name,
              style: ClassroomsTextStyles.tableName.copyWith(color: c.onImpact),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: ClassroomsSizes.centerColumnCount,
            child: Text(
              '${row.studentsPresent}',
              style: ClassroomsTextStyles.tableValue.copyWith(
                color: c.onImpact,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: ClassroomsSizes.centerColumnCount,
            child: Text(
              '${row.staffPresent}',
              style: ClassroomsTextStyles.tableValue.copyWith(
                color: c.onImpact,
              ),
              textAlign: TextAlign.end,
            ),
          ),
          SizedBox(
            width: ClassroomsSizes.centerColumnRatio,
            child: Align(
              alignment: Alignment.centerRight,
              child: _StatePill(row: row),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatePill extends StatelessWidget {
  const _StatePill({required this.row});

  final CenterRatioRow row;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final (fill, ink, label) = switch (row.state) {
      ClassroomRatioState.inRatio => (
        c.successBg,
        c.successFg,
        AppStrings.inRatio,
      ),
      ClassroomRatioState.short => (
        c.dangerBg,
        c.dangerFg,
        ClassroomsStrings.moreStaff(row.staffNeeded),
      ),
      ClassroomRatioState.noStaff => (
        c.well,
        c.ink2,
        ClassroomsStrings.noStaff,
      ),
      ClassroomRatioState.empty => (
        c.well,
        c.ink2,
        ClassroomsStrings.ratioEmpty,
      ),
    };

    return Container(
      padding: ClassroomsSizes.centerPillPad,
      decoration: AppSurfaces.pill(fill: fill).decoration,
      child: Text(
        label,
        style: ClassroomsTextStyles.tablePill.copyWith(color: ink),
      ),
    );
  }
}
