import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_haptics.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';
import 'package:wowcare/core/theme/skeu_decoration.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_colors.dart';

class CustomToggle extends StatefulWidget {
  const CustomToggle({
    super.key,
    required this.label,
    required this.isToggled,
    required this.onToggle,
    this.labelStyle,
    this.labelOnLeftSide = false,
    this.enabled = true,
  });

  final String label;
  final bool isToggled;
  final ValueChanged<bool> onToggle;
  final TextStyle? labelStyle;
  final bool labelOnLeftSide;

  /// When false the toggle is shown in its current state but cannot be tapped
  /// (rendered dimmed). Used e.g. to lock "Requires Admin Approval" while
  /// editing an existing activity.
  final bool enabled;

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
    if (!widget.enabled) return;
    AppHaptics.select();
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
                onTap: widget.enabled ? _handleToggle : null,
                child: AnimatedContainer(
                  height: 28,
                  width: 56,
                  padding: const EdgeInsets.all(4),
                  duration: const Duration(milliseconds: 200),
                  decoration: _internalToggle
                      ? SkeuDecoration(
                          color: AppPalette.statusSuccess,
                          borderRadius: AppRadius.allPill,
                        )
                      : AppSurfaces.trough(),
                  alignment: _internalToggle
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: AppMotion.base,
                    width: 20,
                    decoration: AppSurfaces.knob(),
                  ),
                ),
              ),
            ],
          )
        : Row(
            children: [
              GestureDetector(
                onTap: widget.enabled ? _handleToggle : null,
                child: AnimatedContainer(
                  height: 28,
                  width: 56,
                  padding: const EdgeInsets.all(4),
                  duration: const Duration(milliseconds: 200),
                  decoration: _internalToggle
                      ? SkeuDecoration(
                          color: AppPalette.statusSuccess,
                          borderRadius: AppRadius.allPill,
                        )
                      : AppSurfaces.trough(),
                  alignment: _internalToggle
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: AnimatedContainer(
                    duration: AppMotion.base,
                    width: 20,
                    decoration: AppSurfaces.knob(),
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
