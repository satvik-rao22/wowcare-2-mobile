import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/impact_card.dart';
import 'package:wowcare/redesign/core/widgets/primary_key.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';

/// The card a teacher meets before their classroom unlocks (7e): they are
/// not on the clock, so nobody can be marked yet.
///
/// The one navy surface on the screen and the one pink key on it, because
/// there is exactly one thing to do here.
class TeacherClockCard extends StatelessWidget {
  const TeacherClockCard({
    required this.initials,
    required this.shiftLine,
    required this.onClockIn,
    super.key,
  });

  final String initials;

  /// "Shift 7:30 to 16:30 · 11 minutes late".
  final String shiftLine;

  final VoidCallback onClockIn;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return ImpactCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.clockCardGap,
        children: <Widget>[
          Row(
            spacing: ClassroomsSizes.classroomHeadGap,
            children: <Widget>[
              SurfaceBox(
                surface: AppSurfaces.avatar(
                  c,
                  fill: c.impactBevel,
                  size: ClassroomsSizes.clockAvatar,
                ),
                width: ClassroomsSizes.clockAvatar,
                height: ClassroomsSizes.clockAvatar,
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: ClassroomsTextStyles.clockInitials.copyWith(
                    color: c.onImpact,
                  ),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      ClassroomsStrings.notClockedIn,
                      style: ClassroomsTextStyles.clockTitle.copyWith(
                        color: c.onImpact,
                      ),
                    ),
                    Text(
                      shiftLine,
                      style: ClassroomsTextStyles.clockSub.copyWith(
                        color: c.onImpactSub,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          PrimaryKey(
            label: ClassroomsStrings.clockInNow,
            onTap: onClockIn,
            padding: ClassroomsSizes.clockKeyPad,
          ),
          Text(
            ClassroomsStrings.clockInWhy,
            style: ClassroomsTextStyles.clockWhy.copyWith(
              color: c.onImpactSoft,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
