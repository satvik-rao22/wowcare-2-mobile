import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// A kiosk pad key. Components page `.pinkey`: the deepest rim in the app.
///
/// Radius 18 on a solid 4px key rim, and it sinks the full 4px so the face
/// lands flush. Give it a [label] for a digit or an [icon] for backspace. It
/// fills its slot; the pad lays keys out in rows of `Expanded`.
class PinKey extends StatelessWidget {
  const PinKey({
    this.label,
    this.icon,
    this.onTap,
    this.semanticLabel,
    super.key,
  }) : assert(
         (label == null) != (icon == null),
         'Pass exactly one of label or icon.',
       );

  final String? label;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel ?? label,
      child: Pressable.padKey(
        onTap: onTap,
        builder: (context, t) => SurfaceBox(
          surface: AppSurfaces.padKey(
            c,
            rim: lerpDouble(AppSizes.keyRim, 0, t)!,
          ),
          padding: AppSizes.padKeyPad,
          alignment: Alignment.center,
          width: double.infinity,
          child: label != null
              ? Text(
                  label!,
                  style: AppTextStyles.padKeyLabel.copyWith(color: c.ink),
                )
              : Icon(icon, size: AppSizes.iconKeyGlyph, color: c.ink),
        ),
      ),
    );
  }
}
