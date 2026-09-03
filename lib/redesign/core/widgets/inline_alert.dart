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

  /// A reassurance rather than a warning: the kiosk's geofence line (2c).
  success,
}

/// A message set into the page, above the thing it is about.
class InlineAlert extends StatelessWidget {
  const InlineAlert({
    required this.message,
    this.tone = AlertTone.danger,
    this.icon,
    super.key,
  });

  final String message;
  final AlertTone tone;

  /// Overrides the tone's own glyph. The danger bubble is never replaced.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final isDanger = tone == AlertTone.danger;
    final ink = switch (tone) {
      AlertTone.danger => c.dangerFg,
      AlertTone.info => c.ink2,
      AlertTone.success => c.successFg,
    };

    return Semantics(
      liveRegion: isDanger,
      child: SurfaceBox(
        surface: switch (tone) {
          AlertTone.danger => AppSurfaces.alertDanger(c),
          AlertTone.info => AppSurfaces.alertInfo(c),
          AlertTone.success => AppSurfaces.alertSuccess(c),
        },
        padding: AppSizes.alertPad,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSizes.alertGap,
          children: <Widget>[
            if (isDanger)
              _Bubble(colours: c)
            else
              Icon(
                icon ?? AppIcons.info,
                size: AppSizes.alertIcon,
                color: ink,
              ),
            Expanded(
              child: Text(
                message,
                style: isDanger
                    ? AppTextStyles.alertText.copyWith(color: ink)
                    : AppTextStyles.noteText.copyWith(color: ink),
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
