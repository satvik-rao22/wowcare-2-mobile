import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_sizes.dart';
import 'package:wowcare/redesign/features/classrooms/classrooms_text_styles.dart';

/// The classrooms floor's one action (7a): a plus and its words, on the
/// rimmed pink key, sitting where the round FAB sits.
///
/// The square FAB carries a glyph and nothing else; this screen's key names
/// what it makes, because "Create a classroom" is the whole point of an empty
/// floor. [isDead] is the no-permission state (7j): recessed, in place, and
/// it does not move.
class ExtendedFab extends StatelessWidget {
  const ExtendedFab({
    required this.label,
    this.onTap,
    this.isDead = false,
    this.icon = AppIcons.plus,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;

  /// No permission behind it. Draws recessed and ignores taps.
  final bool isDead;

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    if (isDead) {
      return Semantics(
        button: true,
        enabled: false,
        label: label,
        child: SurfaceBox(
          surface: AppSurfaces.fabDead(c),
          padding: ClassroomsSizes.extendedFabPad,
          child: _content(c.ink3),
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: label,
      child: Pressable.key(
        onTap: onTap,
        builder: (context, t) => SurfaceBox(
          surface: AppSurfaces.keyPrimary(
            c,
            rim: lerpDouble(AppSizes.keyRim, AppSizes.keyRimDown, t)!,
          ),
          padding: ClassroomsSizes.extendedFabPad,
          child: _content(c.onPink),
        ),
      ),
    );
  }

  Widget _content(Color ink) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: ClassroomsSizes.extendedFabGap,
    children: <Widget>[
      Icon(icon, size: ClassroomsSizes.extendedFabGlyph, color: ink),
      Text(label, style: ClassroomsTextStyles.extendedFab.copyWith(color: ink)),
    ],
  );
}
