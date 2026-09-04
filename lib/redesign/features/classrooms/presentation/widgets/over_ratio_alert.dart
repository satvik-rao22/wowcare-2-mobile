import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';

/// The classroom is over its ratio (7e): a red card at the top of the screen
/// saying by how much, in counts.
class OverRatioAlert extends StatelessWidget {
  const OverRatioAlert({required this.title, required this.message, super.key});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: ClassroomsSizes.refusalCardPad,
        decoration: BoxDecoration(
          color: c.dangerBg,
          borderRadius: AppRadii.cardR,
          border: Border.all(color: c.dangerLine),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: ClassroomsSizes.overRatioGap,
          children: <Widget>[
            Icon(
              AppIcons.alertTriangle,
              size: ClassroomsSizes.overRatioGlyph,
              color: c.dangerFg,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: ClassroomsSizes.overRatioTextGap,
                children: <Widget>[
                  Text(
                    title,
                    style: ClassroomsTextStyles.alertTitle.copyWith(
                      color: c.dangerFg,
                    ),
                  ),
                  Text(
                    message,
                    style: ClassroomsTextStyles.alertBody.copyWith(
                      color: c.dangerFg,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
