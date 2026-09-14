import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';

/// Gradient switch used across the app for compact toggles.
class GradientToggleButton extends StatelessWidget {
  const GradientToggleButton({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 44,
    this.height = 22,
    this.disabled = false,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final double width;
  final double height;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final trackGradient = value
        ? AppColors.buildPrimaryGradient()
        : AppColors.buildPrimaryGradient().withOpacity(0.45);

    final knobSize = height - 6;

    return IgnorePointer(
      ignoring: disabled,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: width,
          height: height,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            gradient: disabled ? null : trackGradient,
            color: disabled ? Colors.grey.withValues(alpha: 0.25) : null,
          ),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: knobSize,
            height: knobSize,
            decoration: const BoxDecoration(
              color: AppColors.cardColor,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
