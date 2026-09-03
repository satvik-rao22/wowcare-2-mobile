import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// A quiet ground inside a card: an icon tile, a neutral tag, a subdued row.
/// The alt-well has no recess and no shadow; it is a tint, not a material.
///
/// Give it [onTap] and it sinks as a surface. [subtle] swaps the alt-well
/// tint for the sub ground, which is what an inner row or a legend chip sits
/// on (3A1's status legend).
class AltWellTile extends StatelessWidget {
  const AltWellTile({
    required this.child,
    this.padding = AppSizes.rowPad,
    this.radius = AppRadii.inner,
    this.subtle = false,
    this.onTap,
    this.alignment,
    this.width,
    this.height,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;

  /// Use the sub ground instead of the alt-well tint.
  final bool subtle;

  final VoidCallback? onTap;
  final AlignmentGeometry? alignment;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    final box = SurfaceBox(
      surface: subtle
          ? AppSurfaces.subtle(c, radius: radius)
          : AppSurfaces.altWell(c, radius: radius),
      padding: padding,
      alignment: alignment,
      width: width,
      height: height,
      child: child,
    );

    if (onTap == null) return box;
    return Pressable.surface(onTap: onTap, child: box);
  }
}
