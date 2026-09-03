import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/app_card.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_sizes.dart';
import 'package:wowcare/redesign/features/dashboard/dashboard_text_styles.dart';

/// One tile on the More page (3M).
///
/// The glyph's tint is the group's colour, not the tile's: teal is students,
/// sun is staff, violet is M17 tasks, and everything else is neutral. A badge
/// is pink unless it is counting something on the staff side.
class MoreTile extends StatelessWidget {
  const MoreTile({
    required this.label,
    required this.icon,
    required this.tint,
    required this.glyphColor,
    required this.onTap,
    this.badge,
    this.badgeFill,
    this.badgeInk,
    super.key,
  });

  final String label;
  final IconData icon;
  final Color tint;
  final Color glyphColor;
  final VoidCallback onTap;

  final String? badge;
  final Color? badgeFill;
  final Color? badgeInk;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    return AppCard(
      onTap: onTap,
      padding: DashboardSizes.moreTilePad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: DashboardSizes.moreTileInnerGap,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              SurfaceBox(
                surface: AppSurfaces.glyphTile(
                  c,
                  fill: tint,
                  radius: AppRadii.inner,
                ),
                width: DashboardSizes.moreIconTile,
                height: DashboardSizes.moreIconTile,
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  size: DashboardSizes.moreIconGlyph,
                  color: glyphColor,
                ),
              ),
              const Spacer(),
              if (badge != null)
                Container(
                  constraints: const BoxConstraints(
                    minWidth: DashboardSizes.moreBadge,
                  ),
                  height: DashboardSizes.moreBadge,
                  padding: DashboardSizes.moreBadgePad,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: badgeFill ?? c.pinkBg,
                    borderRadius: AppRadii.pillR,
                  ),
                  child: Text(
                    badge!,
                    style: DashboardTextStyles.moreBadgeText.copyWith(
                      color: badgeInk ?? c.onPinkTint,
                    ),
                  ),
                ),
            ],
          ),
          Text(
            label,
            style: DashboardTextStyles.moreTileLabel.copyWith(color: c.ink),
          ),
        ],
      ),
    );
  }
}
