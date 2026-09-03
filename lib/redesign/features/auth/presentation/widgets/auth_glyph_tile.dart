import 'package:flutter/widgets.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';
import 'package:wowcare/redesign/core/theme/app_surfaces.dart';
import 'package:wowcare/redesign/core/widgets/surface_box.dart';
import 'package:wowcare/redesign/features/auth/auth_sizes.dart';

/// The big tinted tile 1d and 1e put a single glyph on: the teal lock, the
/// green envelope. Sized by its caller, because 1e's is the larger of the two.
class AuthGlyphTile extends StatelessWidget {
  const AuthGlyphTile({
    required this.icon,
    required this.size,
    required this.glyphSize,
    required this.fill,
    required this.glyphColor,
    super.key,
  });

  final IconData icon;
  final double size;
  final double glyphSize;
  final Color fill;
  final Color glyphColor;

  @override
  Widget build(BuildContext context) => SurfaceBox(
    surface: AppSurfaces.glyphTile(
      context.colours,
      fill: fill,
      radius: AuthSizes.tileRadius,
    ),
    width: size,
    height: size,
    alignment: Alignment.center,
    child: Icon(icon, size: glyphSize, color: glyphColor),
  );
}
