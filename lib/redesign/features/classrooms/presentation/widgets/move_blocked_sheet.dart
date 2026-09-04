import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/app_bottom_sheet.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// What the caller chose out of the move refusal.
enum MoveBlockedChoice { transferForToday, signOutFirst }

/// The first refusal (7i): a student who is signed in cannot be moved to
/// another classroom today.
///
/// Moving them would leave today's attendance recorded against a classroom
/// they are not in, so the move is dead in place and the two things that do
/// work are offered instead.
class MoveBlockedSheet extends StatelessWidget {
  const MoveBlockedSheet({
    required this.student,
    required this.targetClassroom,
    super.key,
  });

  final RosterStudent student;

  /// Where the move was headed. Null when no classroom was picked yet.
  final String? targetClassroom;

  static Future<MoveBlockedChoice?> show(
    BuildContext context, {
    required RosterStudent student,
    String? targetClassroom,
  }) => showAppSheet<MoveBlockedChoice>(
    context,
    builder: (_) =>
        MoveBlockedSheet(student: student, targetClassroom: targetClassroom),
  );

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppBottomSheet(
      header: _header(c),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.refusalGap,
        children: <Widget>[
          _reason(c),
          const _DeadOption(
            icon: AppIcons.arrowRight,
            title: ClassroomsStrings.moveNow,
            subtitle: ClassroomsStrings.notWhileSignedIn,
          ),
          AppCard(
            padding: ClassroomsSizes.optionRowPad,
            onTap: () =>
                Navigator.of(context).pop(MoveBlockedChoice.transferForToday),
            child: const _OptionBody(
              icon: AppIcons.calendar,
              title: ClassroomsStrings.transferInstead,
              subtitle: ClassroomsStrings.transferWhy,
              isEnabled: true,
            ),
          ),
        ],
      ),
      footer: <Widget>[
        PrimaryKey(
          label: ClassroomsStrings.signOutFirst(student.firstName),
          onTap: () =>
              Navigator.of(context).pop(MoveBlockedChoice.signOutFirst),
          padding: ClassroomsSizes.footerKeyPad,
        ),
      ],
    );
  }

  Widget _header(Colourway c) => Row(
    spacing: ClassroomsSizes.refusalHeadGap,
    children: <Widget>[
      Container(
        width: ClassroomsSizes.refusalAvatar,
        height: ClassroomsSizes.refusalAvatar,
        padding: const EdgeInsets.all(ClassroomsSizes.rosterRingPad),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: c.signedIn,
            width: ClassroomsSizes.rosterRing,
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: c.studentBg),
          child: Center(
            child: Text(
              student.initials,
              style: ClassroomsTextStyles.refusalInitials.copyWith(
                color: c.student,
              ),
            ),
          ),
        ),
      ),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              student.name,
              style: ClassroomsTextStyles.stateTitle.copyWith(color: c.ink),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              ClassroomsStrings.signedInAt(student.timeLabel),
              style: ClassroomsTextStyles.refusalStatus.copyWith(
                color: c.successFg,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _reason(Colourway c) => Container(
    padding: ClassroomsSizes.refusalCardPad,
    decoration: BoxDecoration(
      color: c.dangerBg,
      borderRadius: AppRadii.cardR,
      border: Border.all(color: c.dangerLine),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: ClassroomsSizes.refusalCardGap,
      children: <Widget>[
        Icon(
          AppIcons.alertCircle,
          size: ClassroomsSizes.refusalGlyph,
          color: c.dangerFg,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: ClassroomsSizes.overRatioTextGap,
            children: <Widget>[
              Text(
                ClassroomsStrings.inClassroomNowTitle,
                style: ClassroomsTextStyles.alertTitle.copyWith(
                  color: c.dangerFg,
                ),
              ),
              Text(
                targetClassroom == null
                    ? ClassroomsStrings.moveBlockedBodyGeneric
                    : ClassroomsStrings.moveBlockedBody(targetClassroom!),
                style: ClassroomsTextStyles.alertBody.copyWith(
                  color: c.dangerFg,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// The option that is refused: still drawn, faded, and it does not move.
class _DeadOption extends StatelessWidget {
  const _DeadOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: ClassroomsSizes.lockedRowOpacity,
    child: AppCard(
      padding: ClassroomsSizes.optionRowPad,
      child: _OptionBody(
        icon: icon,
        title: title,
        subtitle: subtitle,
        isEnabled: false,
      ),
    ),
  );
}

class _OptionBody extends StatelessWidget {
  const _OptionBody({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isEnabled,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Row(
      spacing: ClassroomsSizes.optionGap,
      children: <Widget>[
        SurfaceBox(
          surface: AppSurfaces.glyphTile(
            c,
            fill: c.well,
            radius: ClassroomsSizes.movementTileRadius,
          ),
          width: ClassroomsSizes.movementTile,
          height: ClassroomsSizes.movementTile,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: ClassroomsSizes.movementGlyph,
            color: isEnabled ? c.ink : c.ink3,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: ClassroomsTextStyles.optionTitle.copyWith(
                  color: isEnabled ? c.ink : c.ink2,
                ),
              ),
              Text(
                subtitle,
                style: ClassroomsTextStyles.optionSub.copyWith(color: c.ink3),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
