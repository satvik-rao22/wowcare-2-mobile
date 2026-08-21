import 'package:flutter/material.dart';
import '../../../app/theme/colors.dart';

class PrimaryCircularLoader extends StatelessWidget {
  const PrimaryCircularLoader({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
    this.color,
  });

  final double size;
  final double strokeWidth;

  /// Overrides the default [AppColors.themeColor] — for a spinner drawn
  /// over a dark scrim (e.g. an upload-in-progress overlay on a photo),
  /// where the theme color wouldn't read clearly.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? AppColors.themeColor;
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: AlwaysStoppedAnimation<Color>(resolvedColor),
        backgroundColor: resolvedColor.withValues(alpha: 0.1),
      ),
    );
  }
}
