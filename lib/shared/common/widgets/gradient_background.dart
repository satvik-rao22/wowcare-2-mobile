import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';
import 'package:wowcare/core/theme/app_media_res.dart';

class GradientBackground extends StatelessWidget {
  GradientBackground({
    super.key,
    required this.child,
    this.image,
    this.gradient,
  });

  final Widget child;
  final String? image;
  final LinearGradient? gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints.expand(),
      decoration: BoxDecoration(
        gradient: gradient ?? AppColors.buildScaffoldGradient(),
        image: DecorationImage(
          image: AssetImage(image ?? MediaRes.wowcareMobileBg),
          fit: BoxFit.cover,
        ),
      ),
      child: child,
    );
  }
}
