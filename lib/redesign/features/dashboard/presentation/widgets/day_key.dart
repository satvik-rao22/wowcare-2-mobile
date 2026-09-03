import 'dart:ui' show lerpDouble;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';

/// One key in My day's two-by-two grid.
///
/// Secondary by default; the one pink key on the card is Sign Out, which is
/// the action the screen exists for. A key with nothing to do loses its rim
/// and goes quiet rather than disappearing, so the grid keeps its shape.
class DayKey extends StatelessWidget {
  const DayKey({
    required this.label,
    this.onTap,
    this.icon,
    this.isPrimary = false,
    super.key,
  });

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final enabled = onTap != null;
    final ink = enabled ? (isPrimary ? c.onPink : c.ink) : c.ink3;

    Widget content(double t) => SurfaceBox(
      surface: !enabled
          ? AppSurfaces.keyDisabled(c)
          : isPrimary
          ? AppSurfaces.keyPrimary(
              c,
              rim: lerpDouble(AppSizes.fabRim, 0, t)!,
            )
          : AppSurfaces.keySecondary(c),
      padding: DashboardSizes.dayKeyPad,
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: DashboardSizes.dayKeyGlyphGap,
        children: <Widget>[
          if (icon != null)
            Icon(icon, size: DashboardSizes.dayKeyGlyph, color: ink),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: DashboardTextStyles.dayKeyLabel.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: isPrimary
          ? Pressable.key(onTap: onTap, builder: (context, t) => content(t))
          : Pressable.surface(onTap: onTap, child: content(0)),
    );
  }
}
