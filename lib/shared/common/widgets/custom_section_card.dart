import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';

class CustomSectionCard extends StatelessWidget {
  const CustomSectionCard({
    required this.child,
    this.padding = const EdgeInsets.all(12),
    this.margin,
    this.backgroundColor,
    this.minHeight,
    Key? key,
  }) : super(key: key);

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? minHeight;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: padding,
      constraints: BoxConstraints(
        minHeight: minHeight ?? 0,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorderColor, width: 1.2),
        borderRadius: BorderRadius.circular(12),
        color: backgroundColor ?? AppColors.cardColor,
      ),
      child: child,
    );
  }
}

