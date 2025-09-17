import 'package:flutter/material.dart';
import 'package:wowcare/core/res/colors.dart';

class CustomClearAllChip extends StatelessWidget {
  const CustomClearAllChip({
    required this.onTap,
    super.key,
  });

  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(4),
        splashColor: AppColors.primaryColor.withValues(alpha: 0.2),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(4),
            gradient: AppColors.buildPrimaryGradient(),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          child: const Center(
            child: Text(
              'Clear All',
              textAlign: TextAlign.center,
              maxLines: 2,
              softWrap: true,
              style: const TextStyle(
                color: AppColors.cardColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

