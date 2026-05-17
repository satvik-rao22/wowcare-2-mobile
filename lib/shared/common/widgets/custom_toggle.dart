import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/colors.dart';

class CustomToggle extends StatefulWidget {
  const CustomToggle({
    super.key,
    required this.label,
    required this.isToggled,
    required this.onToggle,
    this.labelStyle,
    this.labelOnLeftSide = false,
  });

  final String label;
  final bool isToggled;
  final ValueChanged<bool> onToggle;
  final TextStyle? labelStyle;
  final bool labelOnLeftSide;

  @override
  State<CustomToggle> createState() => _CustomToggleState();
}

class _CustomToggleState extends State<CustomToggle> {
  late bool _internalToggle;

  @override
  void initState() {
    super.initState();
    _internalToggle = widget.isToggled;
  }

  @override
  void didUpdateWidget(covariant CustomToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep internal state in sync when parent updates `isToggled`
    // (e.g. when filters are applied / cleared, or toggle is driven externally).
    if (oldWidget.isToggled != widget.isToggled &&
        _internalToggle != widget.isToggled) {
      setState(() {
        _internalToggle = widget.isToggled;
      });
    }
  }

  void _handleToggle() {
    setState(() {
      _internalToggle = !_internalToggle;
    });
    widget.onToggle(_internalToggle);
  }

  @override
  Widget build(BuildContext context) {
    return widget.labelOnLeftSide
        ? Row(
            children: [
              if (widget.label.trim().isNotEmpty)
                Text(
                  widget.label,
                  style:
                      widget.labelStyle ??
                      TextStyle(
                        color: AppColors.primaryColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                ),
              if (widget.label.trim().isNotEmpty) const SizedBox(width: 8),
              GestureDetector(
                onTap: _handleToggle,
                child: AnimatedContainer(
                  height: 28,
                  width: 56,
                  padding: const EdgeInsets.all(4),
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: _internalToggle
                        ? AppColors.buildPrimaryGradient()
                        : AppColors.buildPrimaryGradient().withOpacity(0.5),
                  ),
                  alignment: _internalToggle
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.cardColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              GestureDetector(
                onTap: _handleToggle,
                child: AnimatedContainer(
                  height: 28,
                  width: 56,
                  padding: const EdgeInsets.all(4),
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: _internalToggle
                        ? AppColors.buildPrimaryGradient()
                        : AppColors.buildPrimaryGradient().withOpacity(0.5),
                  ),
                  alignment: _internalToggle
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.cardColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              if (widget.label.trim().isNotEmpty) const SizedBox(width: 8),
              if (widget.label.trim().isNotEmpty)
                Text(
                  widget.label,
                  style:
                      widget.labelStyle ??
                      TextStyle(
                        color: AppColors.primaryColor.withValues(alpha: 0.6),
                        fontWeight: FontWeight.w500,
                      ),
                ),
            ],
          );
  }
}
