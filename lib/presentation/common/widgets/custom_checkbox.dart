import 'package:flutter/material.dart';
import 'package:wowcare/core/res/colors.dart';

class CustomCheckbox extends StatelessWidget {
  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.labelStyle,
    this.scale,
    this.borderColor,
  });

  final bool value;
  final ValueChanged<bool?> onChanged;
  final String? label;
  final TextStyle? labelStyle;
  final double? scale;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Transform.scale(
            scale: scale ?? 1.2,
            child: Checkbox(
              activeColor: AppColors.themeColor,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: BorderSide(
                color: borderColor ??
                    AppColors.primaryColor.withValues(alpha: 0.2),
              ),
              value: value,
              visualDensity: const VisualDensity(
                horizontal: VisualDensity.minimumDensity,
                vertical: VisualDensity.minimumDensity,
              ),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(width: 8),
          if (label != null)
            Flexible(
              child: Text(
                label!,
                style: labelStyle ??
                    const TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
        ],
      ),
    );
  }
}

