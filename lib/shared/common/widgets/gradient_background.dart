import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The app's page ground.
///
/// In the skeuomorphic language this is `--surface-page`: a soft radial wash,
/// brightest at the top because the light source is directly above. Every
/// raised card and recessed well in the app is read against it, so it carries
/// no pattern of its own — the previous decorative background image would fight
/// the bevels and shadows that do the work now.
///
/// [image] and [gradient] are still honoured for the few screens that pass a
/// deliberate custom backdrop.
class GradientBackground extends StatelessWidget {
  const GradientBackground({
    super.key,
    required this.child,
    this.image,
    this.gradient,
  });

  final Widget child;
  final String? image;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        gradient: gradient ?? SkeuSurfaces.page,
        image: image == null
            ? null
            : DecorationImage(image: AssetImage(image!), fit: BoxFit.cover),
      ),
      child: child,
    );
  }
}
