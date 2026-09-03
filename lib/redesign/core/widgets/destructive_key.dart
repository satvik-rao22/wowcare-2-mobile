import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// A key that removes, deactivates or logs out. Components page
/// `.key--destructive`.
///
/// Red face on a red rim, and deliberately no glow: danger does not invite a
/// tap. Sinks like the primary key, 3px onto a rim that collapses to 1px.
class DestructiveKey extends StatelessWidget {
  const DestructiveKey({
    required this.label,
    this.onTap,
    this.icon,
    this.expand = true,
    this.padding = AppSizes.keySecondaryPad,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;

  /// Fill the available width. Off, the key hugs its label.
  final bool expand;

  final EdgeInsetsGeometry padding;

  /// An expanding key is as wide as its slot, so a long label ellipsizes
  /// rather than spilling past the face. A hugging key is as wide as its
  /// label, so there is nothing to clip.
  Widget _label(TextStyle style) {
    final text = Text(label, style: style, maxLines: 1);
    if (!expand) return text;
    return Flexible(
      child: Text(
        label,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AppSizes.keyIconGap,
      children: <Widget>[
        if (icon != null) Icon(icon, size: AppSizes.keyGlyph, color: c.onPink),
        _label(AppTextStyles.keyLabelSmall.copyWith(color: c.onPink)),
      ],
    );

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Pressable.key(
        onTap: onTap,
        builder: (context, t) => SurfaceBox(
          surface: AppSurfaces.keyDestructive(
            c,
            rim: lerpDouble(AppSizes.keyRim, AppSizes.keyRimDown, t)!,
          ),
          padding: padding,
          alignment: Alignment.center,
          width: expand ? double.infinity : null,
          child: content,
        ),
      ),
    );
  }
}
