import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// A square key carrying one glyph: the header bar's actions. Components
/// page `.iconkey`.
///
/// 38px at the inner radius by default; pass [AppSizes.backKey] for the 34px
/// back key, which steps down to the tighter back-key radius. [badgeCount]
/// hangs a red bubble off the top-right corner, ringed in the sub ground the
/// way 3A1's bell is.
class IconKey extends StatelessWidget {
  const IconKey({
    required this.icon,
    this.onTap,
    this.size = AppSizes.iconKey,
    this.badgeCount,
    this.semanticLabel,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final double size;

  /// An unread count. Null or zero draws no bubble.
  final int? badgeCount;

  final String? semanticLabel;

  /// The glyph's colour. Defaults to ink.
  final Color? iconColor;

  bool get _isSmall => size < AppSizes.iconKey;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final count = badgeCount ?? 0;

    final face = SurfaceBox(
      surface: AppSurfaces.iconKey(
        c,
        radius: _isSmall ? AppRadii.backKeyR : AppRadii.innerR,
      ),
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: _isSmall ? AppSizes.backKeyGlyph : AppSizes.iconKeyGlyph,
        color: iconColor ?? c.ink,
      ),
    );

    final body = count == 0
        ? face
        : Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              face,
              Positioned(
                top: -AppSizes.iconKeyBadgeOverhang,
                right: -AppSizes.iconKeyBadgeOverhang,
                child: _Badge(count: count),
              ),
            ],
          );

    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      child: Pressable.surface(onTap: onTap, child: body),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    return Container(
      constraints: const BoxConstraints(minWidth: AppSizes.iconKeyBadge),
      height: AppSizes.iconKeyBadge,
      padding: AppSizes.iconKeyBadgePad,
      alignment: Alignment.center,
      decoration: AppSurfaces.badge(c, fill: c.danger, ring: c.sub).decoration,
      child: Text(
        '$count',
        style: AppTextStyles.iconKeyBadge.copyWith(color: c.onPink),
      ),
    );
  }
}
