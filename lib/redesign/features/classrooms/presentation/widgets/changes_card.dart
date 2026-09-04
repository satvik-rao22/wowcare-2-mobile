import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/section_eyebrow.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';

/// One line of "What this changes": a label, and what it becomes.
@immutable
class ChangeLine {
  const ChangeLine({required this.label, required this.value, this.isGood});

  final String label;
  final String value;

  /// Green when the change leaves the classroom in ratio, danger when it does
  /// not, ink when it is neither.
  final bool? isGood;
}

/// What submitting an assignment will do (7g, 7h's review step): the roll,
/// the ratio, and when it applies.
///
/// "Immediately, on submit" is the whole of it. A future-dated move is on the
/// module's costly list and is not offered anywhere in this flow.
class ChangesCard extends StatelessWidget {
  const ChangesCard({required this.lines, super.key});

  final List<ChangeLine> lines;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      padding: ClassroomsSizes.changesCardPad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: ClassroomsSizes.changesGap,
        children: <Widget>[
          const SectionEyebrow(label: ClassroomsStrings.whatThisChanges),
          for (final (i, line) in lines.indexed) ...<Widget>[
            if (i > 0) Container(height: AppSizes.hairline, color: c.divider),
            Row(
              spacing: AppSizes.rowGap,
              children: <Widget>[
                Text(
                  line.label,
                  style: ClassroomsTextStyles.changeLabel.copyWith(
                    color: c.ink2,
                  ),
                ),
                Expanded(
                  child: Text(
                    line.value,
                    style: ClassroomsTextStyles.changeValue.copyWith(
                      color: switch (line.isGood) {
                        true => c.successFg,
                        false => c.dangerFg,
                        null => c.ink,
                      },
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
