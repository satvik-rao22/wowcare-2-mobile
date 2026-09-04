import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/counting_tile.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';
import 'package:wowcare/redesign/features/classrooms/models/models.dart';

/// A population's day in the four states the app names (7f): students in
/// teal, staff in sun, and the same four tiles under each.
class DayBreakdownCard extends StatelessWidget {
  const DayBreakdownCard({
    required this.title,
    required this.breakdown,
    required this.isStaff,
    super.key,
  });

  final String title;
  final DayBreakdown breakdown;

  /// Staff read in sun, students in teal.
  final bool isStaff;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: ClassroomsSizes.profileCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.profileCardGap,
        children: <Widget>[
          SectionEyebrow(
            label: title,
            color: isStaff ? c.staffFg : c.student,
            trailing: Flexible(
              child: Text(
                '${breakdown.expected}',
                style: ClassroomsTextStyles.cardMeta.copyWith(color: c.ink3),
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
                child: CountingTile(
                  value: '${breakdown.signedIn}',
                  label: ClassroomsStrings.signedIn,
                  tone: isStaff ? TileTone.staff : TileTone.success,
                ),
              ),
              Expanded(
                child: CountingTile(
                  value: '${breakdown.notMarked}',
                  label: ClassroomsStrings.notMarked,
                ),
              ),
            ],
          ),
          Row(
            spacing: ClassroomsSizes.statTileGap,
            children: <Widget>[
              Expanded(
                child: CountingTile(
                  value: '${breakdown.absent}',
                  label: ClassroomsStrings.absent,
                  tone: breakdown.absent == 0
                      ? TileTone.neutral
                      : TileTone.danger,
                ),
              ),
              Expanded(
                child: CountingTile(
                  value: '${breakdown.signedOut}',
                  label: ClassroomsStrings.signedOut,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
