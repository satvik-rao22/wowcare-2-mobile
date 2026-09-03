import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/extensions/context_extensions.dart';

/// The ring spinner: a 2.5px arc over a faint track of the same colour (1a's
/// signing-in key).
///
/// 16px by default, which is the size that sits beside a key label. Pass
/// [AppSizes.ringLarge] for a loading screen. Colour defaults to pink; a key
/// passes its own ink.
class LoadingRing extends StatelessWidget {
  const LoadingRing({
    this.size = AppSizes.ringSmall,
    this.color,
    this.strokeWidth = AppSizes.ringStroke,
    super.key,
  });

  final double size;
  final Color? color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    final arc = color ?? context.colours.pink;
    return SizedBox.square(
      dimension: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        strokeCap: StrokeCap.round,
        color: arc,
        backgroundColor: arc.withValues(alpha: AppSizes.ringTrackAlpha),
      ),
    );
  }
}
