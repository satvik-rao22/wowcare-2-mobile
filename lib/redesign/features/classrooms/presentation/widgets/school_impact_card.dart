import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/widgets/impact_card.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// The one fact the classrooms screen leads with (7a): how many students are
/// in, how many staff are on with them, and how full the school is.
///
/// The figures are the school's own readings, not a sum of the cards below:
/// capacity, FTE and the attendance summary are three separate calls the app
/// already makes.
class SchoolImpactCard extends StatelessWidget {
  const SchoolImpactCard({required this.board, super.key});

  final ClassroomBoard board;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final over = board.overRatioCount;

    return ImpactCard(
      padding: ClassroomsSizes.impactPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.impactGap,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            spacing: AppSizes.rowGap,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      ClassroomsStrings.studentsIn(board.studentsPresent),
                      style: ClassroomsTextStyles.impactHeadline.copyWith(
                        color: c.onImpact,
                      ),
                    ),
                    Text(
                      ClassroomsStrings.staffOnDutyAcross(
                        board.staffOnDuty,
                        board.classroomCount,
                      ),
                      style: ClassroomsTextStyles.impactSub.copyWith(
                        color: c.onImpactSub,
                      ),
                    ),
                  ],
                ),
              ),
              StatusPill(
                label: over == 0
                    ? ClassroomsStrings.allInRatio
                    : ClassroomsStrings.classroomsOver(over),
                tone: over == 0 ? PillTone.success : PillTone.danger,
              ),
            ],
          ),
          _ImpactTrough(fraction: board.fillFraction),
          Text(
            ClassroomsStrings.enrolledOfPlaces(
              board.enrolled,
              board.places,
              board.percentFull,
            ),
            style: ClassroomsTextStyles.impactFoot.copyWith(
              color: c.onImpactSub,
            ),
          ),
        ],
      ),
    );
  }
}

/// A trough sunk into the navy card rather than into the tray: the everyday
/// well ground would disappear on this surface, so the recess is the impact
/// shadow and the fill is the pale student teal.
class _ImpactTrough extends StatelessWidget {
  const _ImpactTrough({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Container(
      height: AppSizes.troughHeight,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: c.impactShadow,
        borderRadius: AppRadii.pillR,
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: fraction.clamp(0, 1),
          heightFactor: 1,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: c.studentBg,
              borderRadius: AppRadii.pillR,
            ),
          ),
        ),
      ),
    );
  }
}
