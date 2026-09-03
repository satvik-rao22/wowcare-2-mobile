import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/theme/app_text_styles.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// The one fact on a screen that outranks the rest. Components page
/// `.card--impact`: navy, warm-white ink.
///
/// Text and glyphs inside inherit the warm-white ink, so a child only names a
/// colour when it wants the softer `onImpactSub` for a sub-line.
class ImpactCard extends StatelessWidget {
  const ImpactCard({
    required this.child,
    this.padding = AppSizes.cardPad,
    this.onTap,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;

    final box = SurfaceBox(
      surface: AppSurfaces.impact(c),
      padding: padding,
      child: DefaultTextStyle.merge(
        style: AppTextStyles.body.copyWith(color: c.onImpact),
        child: IconTheme.merge(
          data: IconThemeData(color: c.onImpact),
          child: child,
        ),
      ),
    );

    if (onTap == null) return box;
    return Pressable.surface(onTap: onTap, child: box);
  }
}
