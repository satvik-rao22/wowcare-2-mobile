import 'package:flutter/material.dart';

import '../../../app/theme/colors.dart';

class PrimaryCircularLoader extends StatelessWidget {
  const PrimaryCircularLoader({
    super.key,
    this.size = 32,
    this.strokeWidth = 3,
  });

  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: size,
      width: size,
      child: CircularProgressIndicator(
        strokeWidth: strokeWidth,
        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.themeColor),
        backgroundColor: AppColors.themeColor.withValues(alpha: 0.1),
      ),
    );
  }
}
