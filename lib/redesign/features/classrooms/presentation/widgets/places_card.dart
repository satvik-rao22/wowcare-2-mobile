import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/counting_tile.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/core/widgets/status_pill.dart';
import 'package:wowcare/redesign/core/widgets/trough.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// How full the classroom is (7f): the roll against the places, with what is
/// left of it beside.
class PlacesCard extends StatelessWidget {
  const PlacesCard({required this.summary, super.key});

  final ClassroomSummary summary;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final left = summary.placesLeft;

    return AppCard(
      padding: ClassroomsSizes.profileCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.profileCardGap,
        children: <Widget>[
          const SectionEyebrow(label: ClassroomsStrings.places),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: '${summary.enrolled}',
                    style: ClassroomsTextStyles.placesNumber.copyWith(
                      color: c.ink,
                    ),
                    children: <InlineSpan>[
                      TextSpan(
                        text:
                            ' ${ClassroomsStrings.ofCapacity(summary.capacity)}',
                        style: ClassroomsTextStyles.placesOf.copyWith(
                          color: c.ink3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              StatusPill(
                label: left == 0
                    ? ClassroomsStrings.classroomFull
                    : ClassroomsStrings.placesLeft(left),
                tone: left == 0 ? PillTone.staff : PillTone.student,
              ),
            ],
          ),
          Trough(
            fraction: summary.fillFraction,
            fill: summary.isFull ? c.staff : c.student,
            height: ClassroomsSizes.placesTrough,
          ),
          Row(
            spacing: ClassroomsSizes.statTileGap,
            children: <Widget>[
              Expanded(
                child: CountingTile(
                  value: '${summary.enrolled}',
                  label: ClassroomsStrings.enrolledNow,
                  tone: TileTone.student,
                ),
              ),
              Expanded(
                child: CountingTile(
                  value: '${summary.startingSoon}',
                  label: ClassroomsStrings.startingSoon,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
