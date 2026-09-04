import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// The one-line classroom card a teacher taps to reach the record (7e), and
/// the head of a classroom with nobody in it yet (7j).
class ClassroomMiniCard extends StatelessWidget {
  const ClassroomMiniCard({
    required this.summary,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  final ClassroomSummary summary;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isEmpty = summary.isEmpty;

    return AppCard(
      padding: ClassroomsSizes.miniCardPad,
      onTap: onTap,
      child: Row(
        spacing: ClassroomsSizes.miniGap,
        children: <Widget>[
          SurfaceBox(
            surface: AppSurfaces.avatar(
              c,
              fill: isEmpty ? c.well : c.studentBg,
              size: ClassroomsSizes.miniAvatar,
            ),
            width: ClassroomsSizes.miniAvatar,
            height: ClassroomsSizes.miniAvatar,
            alignment: Alignment.center,
            child: Text(
              summary.initial,
              style: ClassroomsTextStyles.miniInitial.copyWith(
                color: isEmpty ? c.ink3 : c.student,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: ClassroomsSizes.staffRowTextGap,
              children: <Widget>[
                Text(
                  isEmpty
                      ? ClassroomsStrings.ageAndPlaces(
                          summary.ageBand,
                          summary.capacity,
                        )
                      : ClassroomsStrings.ageAndEnrolled(
                          summary.ageBand,
                          summary.enrolled,
                        ),
                  style: ClassroomsTextStyles.miniTitle.copyWith(color: c.ink),
                ),
                Text(
                  subtitle,
                  style: ClassroomsTextStyles.miniSub.copyWith(color: c.ink3),
                ),
              ],
            ),
          ),
          Icon(
            AppIcons.chevronRight,
            size: ClassroomsSizes.cardChevron,
            color: onTap == null ? c.ink3 : c.pink,
          ),
        ],
      ),
    );
  }
}
