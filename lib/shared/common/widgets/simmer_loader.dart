import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

class ShimmerLoaderBox extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;

  const ShimmerLoaderBox({
    super.key,
    required this.child,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppPalette.surfaceField,
      highlightColor: AppPalette.surfaceMuted,
      child: SizedBox(height: height, width: width, child: child),
    );
  }
}

class ShimmerLoaderCard extends StatelessWidget {
  final Widget child;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;
  final Color? cardColor;
  final EdgeInsets? margin;

  const ShimmerLoaderCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.borderRadius,
    this.cardColor,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppPalette.surfaceField,
      highlightColor: AppPalette.surfaceMuted,
      child: Card(
        margin: margin ?? const EdgeInsets.all(8.0),
        color: cardColor ?? AppPalette.surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: borderRadius ?? BorderRadius.circular(8.0),
        ),
        child: SizedBox(height: height, width: width, child: child),
      ),
    );
  }
}
