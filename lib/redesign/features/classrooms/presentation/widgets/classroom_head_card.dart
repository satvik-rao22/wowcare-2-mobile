import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/app_well.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/tone_colors.dart';

/// The card at the head of one classroom (7c): who it is, who is leading it
/// today, and the three figures that matter, over a link to its own record.
class ClassroomHeadCard extends StatelessWidget {
  const ClassroomHeadCard({
    required this.summary,
    required this.staffOnDuty,
    this.onOpenProfile,
    super.key,
  });

  final ClassroomSummary summary;

  /// Staff on the clock right now, break included.
  final int staffOnDuty;

  final VoidCallback? onOpenProfile;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: ClassroomsSizes.headCardPad,
      onTap: onOpenProfile,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.classroomCardGap,
        children: <Widget>[_head(c), _tiles(c)],
      ),
    );
  }

  Widget _head(Colourway c) => Row(
    spacing: ClassroomsSizes.classroomHeadGap,
    children: <Widget>[
      SurfaceBox(
        surface: AppSurfaces.avatar(
          c,
          fill: summary.isEmpty ? c.well : c.studentBg,
          size: ClassroomsSizes.headAvatar,
        ),
        width: ClassroomsSizes.headAvatar,
        height: ClassroomsSizes.headAvatar,
        alignment: Alignment.center,
        child: Text(
          summary.initial,
          style: ClassroomsTextStyles.headInitial.copyWith(
            color: summary.isEmpty ? c.ink3 : c.student,
          ),
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: ClassroomsSizes.headTextGap,
          children: <Widget>[
            Wrap(
              spacing: ClassroomsSizes.agePillGap,
              runSpacing: ClassroomsSizes.agePillGap,
              children: <Widget>[
                Container(
                  padding: ClassroomsSizes.agePillPad,
                  decoration: AppSurfaces.pill(fill: c.studentBg).decoration,
                  child: Text(
                    summary.ageBand,
                    style: ClassroomsTextStyles.smallPill.copyWith(
                      color: c.student,
                    ),
                  ),
                ),
                StatusPill(
                  label: summary.isInRatio
                      ? AppStrings.inRatio
                      : ClassroomsStrings.moreStaff(summary.staffNeeded),
                  tone: summary.ratioState.pillTone,
                  small: true,
                ),
              ],
            ),
            _leadLine(c),
          ],
        ),
      ),
      if (onOpenProfile != null) _profileLink(c),
    ],
  );

  Widget _leadLine(Colourway c) {
    final lead = summary.leadName;

    return Row(
      spacing: ClassroomsSizes.headLeadGap,
      children: <Widget>[
        if (lead != null)
          SurfaceBox(
            surface: AppSurfaces.avatar(
              c,
              fill: c.staffBg,
              size: ClassroomsSizes.headLeadAvatar,
            ),
            width: ClassroomsSizes.headLeadAvatar,
            height: ClassroomsSizes.headLeadAvatar,
            alignment: Alignment.center,
            child: Text(
              summary.leadInitials ?? '',
              style: ClassroomsTextStyles.headLeadInitials.copyWith(
                color: c.staffFg,
              ),
            ),
          ),
        Expanded(
          child: Text(
            lead == null
                ? ClassroomsStrings.noLeadToday
                : ClassroomsStrings.isLeadingToday(lead),
            style: ClassroomsTextStyles.headLead.copyWith(color: c.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _profileLink(Colourway c) => SizedBox(
    width: ClassroomsSizes.profileLinkWidth,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          ClassroomsStrings.classroomProfile,
          style: ClassroomsTextStyles.headLink.copyWith(color: c.pink),
          textAlign: TextAlign.end,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Icon(
          AppIcons.chevronRight,
          size: ClassroomsSizes.cardChevron,
          color: c.pink,
        ),
      ],
    ),
  );

  Widget _tiles(Colourway c) => Row(
    spacing: ClassroomsSizes.countTileGap,
    children: <Widget>[
      Expanded(
        child: _CountTile(
          value: '${summary.studentsPresent}',
          label: ClassroomsStrings.tileStudentsIn,
          valueColor: c.student,
        ),
      ),
      Expanded(
        child: _CountTile(
          value: '$staffOnDuty',
          label: ClassroomsStrings.tileStaffOnDuty,
          valueColor: c.staffFg,
        ),
      ),
      Expanded(
        child: _CountTile(
          value: ClassroomsStrings.placesFilled(
            summary.enrolled,
            summary.capacity,
          ),
          label: ClassroomsStrings.tilePlacesFilled,
          valueColor: c.ink,
        ),
      ),
    ],
  );
}

/// A figure sunk into the header card, in its domain's ink.
class _CountTile extends StatelessWidget {
  const _CountTile({
    required this.value,
    required this.label,
    required this.valueColor,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppWell(
      padding: ClassroomsSizes.countTilePad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: ClassroomsSizes.countTileTextGap,
        children: <Widget>[
          Text(
            value,
            style: ClassroomsTextStyles.countValue.copyWith(color: valueColor),
            maxLines: 1,
          ),
          Text(
            label,
            style: ClassroomsTextStyles.countLabel.copyWith(color: c.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
