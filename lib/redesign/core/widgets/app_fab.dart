import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_icons.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/constants/app_strings.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// The create key. Components page `.fab`: 58px, radius 14, a plus and
/// nothing else.
///
/// Pink on a 3px rim that it sinks flush onto. [isDead] is the no-permission
/// state: recessed into the tray, ink3 glyph, still in place, does not move.
///
/// This is only the key. A screen places it through `ScreenScaffold.fab`,
/// which knows where it goes (20 from the right, 16 above the tab bar).
class AppFab extends StatelessWidget {
  const AppFab({
    this.onTap,
    this.isDead = false,
    this.icon = AppIcons.plus,
    this.semanticLabel = AppStrings.add,
    super.key,
  });

  final VoidCallback? onTap;

  /// No permission behind it. Draws recessed and ignores taps.
  final bool isDead;

  final IconData icon;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    if (isDead) {
      return Semantics(
        button: true,
        enabled: false,
        label: semanticLabel,
        child: SurfaceBox(
          surface: AppSurfaces.fabDead(c),
          width: AppSizes.fab,
          height: AppSizes.fab,
          alignment: Alignment.center,
          child: Icon(icon, size: AppSizes.fabGlyph, color: c.ink3),
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: Pressable.key(
        onTap: onTap,
        builder: (context, t) => SurfaceBox(
          surface: AppSurfaces.fab(c, rim: lerpDouble(AppSizes.fabRim, 0, t)!),
          width: AppSizes.fab,
          height: AppSizes.fab,
          alignment: Alignment.center,
          child: Icon(icon, size: AppSizes.fabGlyph, color: c.onPink),
        ),
      ),
    );
  }
}
