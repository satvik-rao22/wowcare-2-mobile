import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/profile/profile_sizes.dart';

/// The row of keys docked under a form: 13b's Cancel and Save, and Change
/// Password's.
///
/// The card ground with a hairline over it, and an [IntrinsicHeight] around
/// the content. That last part is load-bearing: a key's face is centred
/// inside its own surface, so given a tall bounded slot it would stretch to
/// fill it, and a `Scaffold`'s bottom slot is exactly that. Measuring the keys
/// first pins the bar to their height.
///
/// A feature may not import another feature, so this is M05's `DockedBar`
/// again rather than a shared one; the shape belongs in `core/widgets` the
/// next time a third module wants it.
class DockedBar extends StatelessWidget {
  const DockedBar({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) => SurfaceBox(
    surface: AppSurfaces.tabBar(context.colours),
    padding: ProfileSizes.footerPad,
    child: IntrinsicHeight(child: child),
  );
}
