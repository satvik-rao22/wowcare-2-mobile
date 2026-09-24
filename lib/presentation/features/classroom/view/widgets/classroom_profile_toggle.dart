import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_icon.dart';
import 'package:wowcare/core/theme/app_media_res.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_press.dart';

/// The key beside the classroom picker that swaps between the classroom's
/// tabs and its profile. Both screens draw this one widget so they match.
///
/// A navy list glyph on an icon key. The asset used to be a filled gradient
/// disc with the list knocked out in white, and [AppIcon]'s one-colour tint
/// painted both the same navy, which left a solid 32px circle.
class ClassroomProfileToggle extends StatelessWidget {
  const ClassroomProfileToggle({
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final String tooltip;

  /// Null disables the key (no classroom to show).
  final VoidCallback? onPressed;

  static const double _box = 38;
  static const double _glyph = 20;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 8),
    child: Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        label: tooltip,
        child: SkeuPressable.surface(
          onTap: onPressed,
          child: Container(
            width: _box,
            height: _box,
            alignment: Alignment.center,
            decoration: AppSurfaces.iconKey(),
            child: AppIcon(
              MediaRes.classroomInfoIcon,
              size: _glyph,
              tone: onPressed == null ? IconTone.muted : IconTone.standard,
            ),
          ),
        ),
      ),
    ),
  );
}
