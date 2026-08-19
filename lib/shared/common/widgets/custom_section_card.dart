import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The app's generic content card.
///
/// A raised panel in the skeuomorphic language: a shallow vertical gradient
/// face, a lit top bevel and a navy-tinted drop shadow, so a card reads as a
/// solid object sitting on the page rather than an outlined rectangle. The
/// hairline border it used to draw is gone — depth now comes from the light.
class CustomSectionCard extends StatelessWidget {
  const CustomSectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin,
    this.backgroundColor,
    this.minHeight,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  /// A flat colour override. When null the card takes the standard
  /// `--surface-card` gradient face.
  final Color? backgroundColor;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return SkeuPanel(
      margin: margin,
      padding: padding,
      radius: SkeuRadius.xl,
      color: backgroundColor,
      gradient: backgroundColor == null ? SkeuSurfaces.card : null,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: minHeight ?? 0),
        child: child,
      ),
    );
  }
}
