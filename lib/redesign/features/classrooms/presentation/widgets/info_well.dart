import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/widgets/app_well.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';

/// A quiet explanation sunk into the page: what a filter covers (7d), what
/// being in a classroom does and does not mean (7h).
///
/// A well rather than a card, because there is nothing here to press.
class InfoWell extends StatelessWidget {
  const InfoWell({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppWell(
      padding: ClassroomsSizes.infoWellPad,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: ClassroomsSizes.infoWellGap,
        children: <Widget>[
          Icon(
            AppIcons.info,
            size: ClassroomsSizes.infoWellGlyph,
            color: c.ink2,
          ),
          Expanded(
            child: Text(
              message,
              style: ClassroomsTextStyles.infoWell.copyWith(color: c.ink2),
            ),
          ),
        ],
      ),
    );
  }
}
