import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/theme/colourway.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// One slot in the tab bar.
@immutable
class AppTabItem {
  const AppTabItem({required this.icon, required this.label, this.badgeCount});

  final IconData icon;
  final String label;

  /// An unread count on the tile's corner. Null or zero draws nothing.
  final int? badgeCount;
}

/// The five-slot bottom bar. Components page `.tabbar`.
///
/// 88px tall including its 22px bottom pad, which stretches to the device's
/// own bottom inset when that is deeper. The active slot gets a pink-tinted
/// tile with a lit bevel, and its label goes pink at 700. [selectedIndex]
/// is nullable on purpose: a drill-down screen highlights nothing.
class AppTabBar extends StatelessWidget {
  const AppTabBar({
    required this.items,
    required this.onSelect,
    this.selectedIndex,
    super.key,
  });

  final List<AppTabItem> items;
  final ValueChanged<int> onSelect;
  final int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final bottomPad = math.max(
      AppSizes.tabBarPad.bottom,
      context.safeArea.bottom,
    );

    return SurfaceBox(
      surface: AppSurfaces.tabBar(c),
      padding: AppSizes.tabBarPad.copyWith(bottom: bottomPad),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          for (final (i, item) in items.indexed)
            _TabSlot(
              item: item,
              isActive: i == selectedIndex,
              onTap: () => onSelect(i),
            ),
        ],
      ),
    );
  }
}

class _TabSlot extends StatelessWidget {
  const _TabSlot({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  final AppTabItem item;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final ink = isActive ? c.pink : c.ink3;
    final count = item.badgeCount ?? 0;

    final glyph = Icon(item.icon, size: AppSizes.tabGlyph, color: ink);
    final tile = isActive
        ? SurfaceBox(
            surface: AppSurfaces.tabTileActive(c),
            width: AppSizes.tabGlyphTile,
            height: AppSizes.tabGlyphTile,
            alignment: Alignment.center,
            child: glyph,
          )
        : SizedBox.square(
            dimension: AppSizes.tabGlyphTile,
            child: Center(child: glyph),
          );

    return Semantics(
      button: true,
      selected: isActive,
      label: item.label,
      child: Pressable.surface(
        onTap: onTap,
        child: SizedBox(
          width: AppSizes.tabItemWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: AppSizes.tabItemGap,
            children: <Widget>[
              Stack(
                clipBehavior: Clip.none,
                children: <Widget>[
                  tile,
                  if (count > 0)
                    Positioned(
                      top: AppSizes.tabBadgeInset,
                      right: AppSizes.tabBadgeInset,
                      child: _TabBadge(count: count, colours: c),
                    ),
                ],
              ),
              Text(
                item.label,
                style: AppTextStyles.navLabel.copyWith(
                  color: ink,
                  fontWeight: isActive ? FontWeight.w700 : null,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabBadge extends StatelessWidget {
  const _TabBadge({required this.count, required this.colours});

  final int count;
  final Colourway colours;

  @override
  Widget build(BuildContext context) => Container(
    constraints: const BoxConstraints(minWidth: AppSizes.badgeMinWidth),
    height: AppSizes.badgeHeight,
    padding: AppSizes.badgePad,
    alignment: Alignment.center,
    decoration: AppSurfaces.badge(colours).decoration,
    child: Text(
      '$count',
      style: AppTextStyles.badge.copyWith(color: colours.onPink),
    ),
  );
}
