import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_radii.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';

/// Anything recessed into a card or the tray. Components page `.well`.
///
/// A well is never tappable: it is where a value lives, a knob slides or text
/// is typed. Fields and search boxes have their own widgets on the shallower
/// `field` recipe; this is the deeper everyday well.
class AppWell extends StatelessWidget {
  const AppWell({
    required this.child,
    this.padding = AppSizes.fieldPad,
    this.radius = AppRadii.inner,
    this.alignment,
    this.width,
    this.height,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double radius;
  final AlignmentGeometry? alignment;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) => SurfaceBox(
    surface: AppSurfaces.well(context.colours, radius: radius),
    padding: padding,
    alignment: alignment,
    width: width,
    height: height,
    child: child,
  );
}
