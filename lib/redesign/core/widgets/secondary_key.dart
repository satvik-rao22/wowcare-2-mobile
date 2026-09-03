import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// Every action that is not the one action. Components page `.key--secondary`.
///
/// A card's face at a key's radius, so it reads as raised rather than filled.
/// It has no rim, so it sinks as a surface: 2px. Null [onTap] renders it
/// inert, in place, at the same weight.
class SecondaryKey extends StatelessWidget {
  const SecondaryKey({
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

    final box = SurfaceBox(
      surface: AppSurfaces.keySecondary(c),
      padding: padding,
      alignment: Alignment.center,
      width: expand ? double.infinity : null,
      child: Row(
        mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: AppSizes.keyIconGap,
        children: <Widget>[
          if (icon != null) Icon(icon, size: AppSizes.keyGlyph, color: c.ink),
          _label(AppTextStyles.keyLabelSmall.copyWith(color: c.ink)),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Pressable.surface(onTap: onTap, child: box),
    );
  }
}
