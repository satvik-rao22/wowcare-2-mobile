import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class CustomClearAllChip extends StatelessWidget {
  const CustomClearAllChip({
    required this.onTap,
    this.label = 'Clear All',
    this.fontSize,
    this.fontWeight,
    this.borderRadius,
    super.key,
  });

  final void Function()? onTap;
  final String label;
  final double? fontSize;
  final FontWeight? fontWeight;
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(borderRadius ?? 4),
        splashColor: AppColors.primaryColor.withValues(alpha: 0.2),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: AppColors.buildPrimaryGradient(),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              softWrap: true,
              style: TextStyle(
                fontFamily: 'Manrope',
                color: AppColors.cardColor,
                fontSize: fontSize ?? 13,
                fontWeight: fontWeight ?? FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
