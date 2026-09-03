import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/pressable.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// Anything raised off the tray. Components page `.card`.
///
/// A tappable card takes [onTap] and sinks as a surface: 2px, with the barely
/// there shrink. [lineColor] swaps the hairline for a domain or status line,
/// the way an attention card takes the danger line (3A1).
class AppCard extends StatelessWidget {
  const AppCard({
    required this.child,
    this.padding = AppSizes.cardPad,
    this.raised = false,
    this.onTap,
    this.lineColor,
    this.clipContent = false,
    this.width,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  /// Sits visibly higher than its neighbours: a hero, a sheet's header card.
  final bool raised;

  final VoidCallback? onTap;

  /// Replaces the card hairline. Null keeps the everyday one.
  final Color? lineColor;

  /// Clip the content to the card's corners: images, troughs, edge-to-edge
  /// rows.
  final bool clipContent;

  final double? width;

  @override
  Widget build(BuildContext context) {
    final c = context.colours;
    var surface = raised ? AppSurfaces.cardRaised(c) : AppSurfaces.card(c);
    if (lineColor != null) {
      surface = surface.copyWith(
        decoration: surface.decoration.copyWith(
          border: Border.all(color: lineColor!),
        ),
      );
    }

    final box = SurfaceBox(
      surface: surface,
      padding: padding,
      width: width,
      clipContent: clipContent,
      child: child,
    );

    if (onTap == null) return box;
    return Pressable.surface(onTap: onTap, child: box);
  }
}
