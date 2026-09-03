import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// How loud an inline alert is.
enum AlertTone {
  /// The red tint with a "!" bubble: a rejected sign-in (1a).
  danger,

  /// A quiet note on the alt-well: a scope explanation (5a).
  info,
}

/// A message set into the page, above the thing it is about.
class InlineAlert extends StatelessWidget {
  const InlineAlert({
    required this.message,
    this.tone = AlertTone.danger,
    super.key,
  });

  final String message;
  final AlertTone tone;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isDanger = tone == AlertTone.danger;

    return Semantics(
      liveRegion: isDanger,
      child: SurfaceBox(
        surface: isDanger
            ? AppSurfaces.alertDanger(c)
            : AppSurfaces.alertInfo(c),
        padding: AppSizes.alertPad,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSizes.alertGap,
          children: <Widget>[
            if (isDanger)
              _Bubble(colours: c)
            else
              Icon(AppIcons.info, size: AppSizes.alertIcon, color: c.ink2),
            Expanded(
              child: Text(
                message,
                style: isDanger
                    ? AppTextStyles.alertText.copyWith(color: c.dangerFg)
                    : AppTextStyles.noteText.copyWith(color: c.ink2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.colours});

  final Colourway colours;

  @override
  Widget build(BuildContext context) => Container(
    width: AppSizes.alertBubble,
    height: AppSizes.alertBubble,
    alignment: Alignment.center,
    decoration: BoxDecoration(shape: BoxShape.circle, color: colours.danger),
    child: Text(
      AppStrings.alertMark,
      style: AppTextStyles.alertBubble.copyWith(color: colours.onPink),
    ),
  );
}
