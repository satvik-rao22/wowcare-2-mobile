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
      child: ShaderMask(
        shaderCallback: (Rect bounds) {
          return AppColors.buildPrimaryGradient()
              .createShader(Offset.zero & bounds.size);
        },
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          backgroundColor: Colors.transparent,
        ),
      ),
    );
  }
}


