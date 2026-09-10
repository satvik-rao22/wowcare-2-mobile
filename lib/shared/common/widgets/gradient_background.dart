import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/skeu_decoration.dart';

/// The page ground.
///
/// Named for the wash it used to paint. Under the flat skeuomorphic skin it
/// paints the warm tray `#FBF8F2` and nothing else: no gradient, and no
/// photographic backdrop, because a picture behind the content fights the
/// flat material that everything on top of it is built from.
///
/// One escape hatch survives: [image] still stamps a backdrop, and only
/// `page_under_construction` asks for one.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.image,
  });

  final Widget child;
  final String? image;

  @override
  Widget build(BuildContext context) {
    final SkeuDecoration ground = AppSurfaces.tray();
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: image == null
          ? ground
          : BoxDecoration(
              color: ground.color,
              image: DecorationImage(
                image: AssetImage(image!),
                fit: BoxFit.cover,
              ),
            ),
      child: child,
    );
  }
}
