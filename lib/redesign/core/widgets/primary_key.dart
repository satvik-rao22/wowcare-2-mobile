import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/loading_ring.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// The one action on a screen. Components page `.key--primary`.
///
/// Pink, on a 4px rim that collapses to 1px as the face sinks 3px, so the
/// rim's bottom edge never moves. [isLoading] swaps the leading glyph for the
/// 16px ring and stops the key responding. [enabled] false renders the
/// disabled recipe: well fill, ink3 label, no rim, and no sink.
class PrimaryKey extends StatelessWidget {
  const PrimaryKey({
    required this.label,
    this.onTap,
    this.icon,
    this.isLoading = false,
    this.enabled = true,
    this.expand = true,
    this.padding = AppSizes.keyPrimaryPad,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;

  /// A glyph before the label. Hidden while [isLoading].
  final IconData? icon;

  final bool isLoading;
  final bool enabled;

  /// Fill the available width. Off, the key hugs its label.
  final bool expand;

  final EdgeInsetsGeometry padding;

  bool get _isActive => enabled && !isLoading && onTap != null;

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
    final ink = enabled ? c.onPink : c.ink3;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: AppSizes.keyIconGap,
      children: <Widget>[
        if (isLoading)
          LoadingRing(color: ink)
        else if (icon != null)
          Icon(icon, size: AppSizes.keyGlyph, color: ink),
        _label(AppTextStyles.keyLabel.copyWith(color: ink)),
      ],
    );

    final semantics = Semantics(
      button: true,
      enabled: _isActive,
      label: label,
      child: enabled
          ? Pressable.key(
              onTap: _isActive ? onTap : null,
              builder: (context, t) => SurfaceBox(
                surface: AppSurfaces.keyPrimary(
                  c,
                  rim: lerpDouble(AppSizes.keyRim, AppSizes.keyRimDown, t)!,
                ),
                padding: padding,
                alignment: Alignment.center,
                child: content,
              ),
            )
          : SurfaceBox(
              surface: AppSurfaces.keyDisabled(c),
              padding: padding,
              alignment: Alignment.center,
              child: content,
            ),
    );

    return expand
        ? SizedBox(width: double.infinity, child: semantics)
        : semantics;
  }
}
