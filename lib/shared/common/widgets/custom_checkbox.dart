import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';

class CustomCheckbox extends StatelessWidget {
  const CustomCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.label,
    this.labelStyle,
    this.scale,
    this.borderColor,
    this.usingInkwell = false,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final String? label;
  final TextStyle? labelStyle;
  final double? scale;
  final Color? borderColor;
  final bool usingInkwell;

  @override
  Widget build(BuildContext context) {
    final bool isInteractive = onChanged != null;
    return usingInkwell
        ? Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Transform.scale(
                scale: scale ?? 1.2,
                child: Checkbox(
                  activeColor: AppColors.themeColor,
                  checkColor: AppColors.whiteColor,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  side: BorderSide(
                    color:
                        borderColor ??
                        AppColors.primaryColor.withValues(alpha: 0.2),
                  ),
                  value: value,
                  visualDensity: const VisualDensity(
                    horizontal: VisualDensity.minimumDensity,
                    vertical: VisualDensity.minimumDensity,
                  ),
                  // Override disabled state to prevent grey overlay
                  fillColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.disabled)) {
                      return value ? AppColors.themeColor : Colors.transparent;
                    }
                    return value ? AppColors.themeColor : Colors.transparent;
                  }),
                  // Optional: remove ripple when disabled
                  overlayColor: WidgetStateProperty.all(Colors.transparent),
                  onChanged: isInteractive ? onChanged : null,
                ),
              ),
              const SizedBox(width: 8),
              if (label != null)
                Flexible(
                  child: Text(
                    label!,
                    style:
                        labelStyle ??
                        const TextStyle(
                          color: AppColors.primaryColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
            ],
          )
        : GestureDetector(
            onTap: isInteractive ? () => onChanged!(!value) : null,
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
                      color:
                          borderColor ??
                          AppColors.primaryColor.withValues(alpha: 0.2),
                    ),
                    value: value,
                    visualDensity: const VisualDensity(
                      horizontal: VisualDensity.minimumDensity,
                      vertical: VisualDensity.minimumDensity,
                    ),
                    onChanged: isInteractive ? onChanged : null,
                  ),
                ),
                const SizedBox(width: 8),
                if (label != null)
                  Flexible(
                    child: Text(
                      label!,
                      style:
                          labelStyle ??
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
