import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_strings.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';

/// What sits over the roster until the teacher is on the clock (7e).
///
/// The rows stay visible under it, dimmed: who is expected is readable, and
/// nothing on the list can be marked yet.
class LockedOverlay extends StatelessWidget {
  const LockedOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Positioned.fill(
      child: ColoredBox(
        color: c.page.withValues(alpha: ClassroomsSizes.lockScrimAlpha),
        child: Center(
          child: AppCard(
            padding: ClassroomsSizes.lockCardPad,
            raised: true,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: ClassroomsSizes.lockCardGap,
              children: <Widget>[
                SurfaceBox(
                  surface: AppSurfaces.emptyIcon(c),
                  width: ClassroomsSizes.lockIcon,
                  height: ClassroomsSizes.lockIcon,
                  alignment: Alignment.center,
                  child: Icon(
                    AppIcons.lock,
                    size: ClassroomsSizes.lockGlyph,
                    color: c.ink2,
                  ),
                ),
                Text(
                  ClassroomsStrings.lockedTitle,
                  style: ClassroomsTextStyles.inlineEmptyTitle.copyWith(
                    color: c.ink2,
                  ),
                  textAlign: TextAlign.center,
                ),
                Text(
                  ClassroomsStrings.lockedBody,
                  style: ClassroomsTextStyles.alertBody.copyWith(color: c.ink3),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
