import 'package:flutter/material.dart';
import 'package:schoolerp/core/res/colors.dart';

class GradientCircularProgress extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final String? loadingText;
  final TextStyle? textStyle;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const GradientCircularProgress({
    Key? key,
    this.size = 50,
    this.strokeWidth = 3,
    this.loadingText,
    this.textStyle,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      margin: margin,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: size,
            width: size,
            child: CircularProgressIndicator(
              strokeWidth: strokeWidth,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.primaryGradientColors.first,
              ),
              backgroundColor: Colors.grey[300],
            ),
          ),
          if (loadingText != null) ...[
            const SizedBox(height: 8),
            Text(
              loadingText!,
              style: textStyle ?? TextStyle(
                color: AppColors.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
} 