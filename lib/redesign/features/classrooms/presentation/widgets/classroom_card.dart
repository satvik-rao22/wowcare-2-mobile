import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/core/widgets/trough.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';
import 'package:wowcare/redesign/features/classrooms/presentation/widgets/tone_colors.dart';

/// One classroom on the floor (7a).
///
/// The ratio is counts and a two-state pill: how many students are in, how
/// many staff are with them, and either In Ratio or how many more are wanted.
/// A classroom that is short takes the danger hairline and says so in words
/// under the bar.
class ClassroomCard extends StatelessWidget {
  const ClassroomCard({required this.classroom, this.onTap, super.key});

  final ClassroomSummary classroom;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final state = classroom.ratioState;

    return AppCard(
      padding: ClassroomsSizes.classroomCardPad,
      onTap: onTap,
      lineColor: state.isShort ? c.dangerLine : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.classroomCardGap,
        children: <Widget>[
          _head(c, state),
          if (!classroom.isEmpty)
            Trough(
              fraction: classroom.fillFraction,
              fill: classroom.isFull ? c.staff : c.student,
              height: ClassroomsSizes.capacityBar,
            ),
          _foot(c),
          if (state.isShort)
            _AlertLine(
              message: ClassroomsStrings.needsMoreStaff(classroom.staffNeeded),
            ),
        ],
      ),
    );
  }

  Widget _head(Colourway c, ClassroomRatioState state) => Row(
    spacing: ClassroomsSizes.classroomHeadGap,
    children: <Widget>[
      SurfaceBox(
        surface: AppSurfaces.avatar(
          c,
          fill: classroom.isEmpty ? c.well : c.studentBg,
          size: ClassroomsSizes.classroomInitial,
        ),
        width: ClassroomsSizes.classroomInitial,
        height: ClassroomsSizes.classroomInitial,
        alignment: Alignment.center,
        child: Text(
          classroom.initial,
          style: ClassroomsTextStyles.classroomInitial.copyWith(
            color: classroom.isEmpty ? c.ink3 : c.student,
          ),
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: ClassroomsSizes.classroomTitleGap,
          children: <Widget>[
            Text(
              classroom.name,
              style: ClassroomsTextStyles.classroomName.copyWith(color: c.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // A Wrap rather than a Row: a long age band and a long capacity
            // line stack rather than pushing each other off the card.
            Wrap(
              spacing: ClassroomsSizes.agePillGap,
              runSpacing: ClassroomsSizes.agePillGap,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                _AgePill(label: classroom.ageBand),
                Text(
                  ClassroomsStrings.ofPlaces(
                    classroom.enrolled,
                    classroom.capacity,
                  ),
                  style: ClassroomsTextStyles.capacityLine.copyWith(
                    color: c.ink3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
      StatusPill(label: _ratioLabel(state), tone: state.pillTone, small: true),
      Icon(
        AppIcons.chevronRight,
        size: ClassroomsSizes.cardChevron,
        color: c.ink3,
      ),
    ],
  );

  String _ratioLabel(ClassroomRatioState state) => switch (state) {
    ClassroomRatioState.inRatio => AppStrings.inRatio,
    ClassroomRatioState.short => ClassroomsStrings.moreStaff(
      classroom.staffNeeded,
    ),
    ClassroomRatioState.noStaff => ClassroomsStrings.noStaffIn,
    ClassroomRatioState.empty => ClassroomsStrings.ratioEmpty,
  };

  Widget _foot(Colourway c) {
    final lead = classroom.leadName;

    return Row(
      spacing: ClassroomsSizes.leadGap,
      children: <Widget>[
        SurfaceBox(
          surface: AppSurfaces.avatar(
            c,
            fill: lead == null ? c.well : c.staffBg,
            size: ClassroomsSizes.leadAvatar,
          ),
          width: ClassroomsSizes.leadAvatar,
          height: ClassroomsSizes.leadAvatar,
          alignment: Alignment.center,
          child: Text(
            classroom.leadInitials ?? classroom.initial,
            style: ClassroomsTextStyles.leadInitials.copyWith(
              color: lead == null ? c.ink3 : c.staffFg,
            ),
          ),
        ),
        Expanded(
          child: Text(
            lead == null
                ? (classroom.hasStaff
                      ? ClassroomsStrings.noLeadAssigned
                      : ClassroomsStrings.noStaffClockedIn)
                : ClassroomsStrings.leading(lead),
            style: ClassroomsTextStyles.footLine.copyWith(color: c.ink2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          ClassroomsStrings.presentCount(classroom.studentsPresent),
          style: ClassroomsTextStyles.footCount.copyWith(color: c.ink),
        ),
        Text(
          classroom.hasStaff
              ? ClassroomsStrings.staffCount(classroom.staffPresent)
              : ClassroomsStrings.noStaff,
          style: ClassroomsTextStyles.footLine.copyWith(color: c.ink3),
        ),
      ],
    );
  }
}

/// The age band, in the student teal.
class _AgePill extends StatelessWidget {
  const _AgePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return Container(
      padding: ClassroomsSizes.agePillPad,
      decoration: AppSurfaces.pill(fill: c.studentBg).decoration,
      child: Text(
        label,
        style: ClassroomsTextStyles.smallPill.copyWith(color: c.student),
      ),
    );
  }
}

/// The red line under a short classroom, in words rather than a figure.
class _AlertLine extends StatelessWidget {
  const _AlertLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Container(
      padding: ClassroomsSizes.alertPad,
      decoration: BoxDecoration(
        color: c.dangerBg,
        borderRadius: AppRadii.innerR,
        border: Border.all(color: c.dangerLine),
      ),
      child: Row(
        spacing: ClassroomsSizes.alertGap,
        children: <Widget>[
          Icon(
            AppIcons.alertTriangle,
            size: ClassroomsSizes.alertGlyph,
            color: c.dangerFg,
          ),
          Expanded(
            child: Text(
              message,
              style: ClassroomsTextStyles.alertLine.copyWith(color: c.dangerFg),
            ),
          ),
        ],
      ),
    );
  }
}
