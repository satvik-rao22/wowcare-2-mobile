import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

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
                      SkeuText.body(color: SkeuColors.inkSoft),
                ),
              if (widget.label.trim().isNotEmpty) const SizedBox(width: 8),
              Opacity(
                opacity: widget.enabled ? 1 : .5,
                child: SkeuSwitch(
                  value: _internalToggle,
                  width: 52,
                  height: 28,
                  onChanged: widget.enabled ? (_) => _handleToggle() : null,
                ),
              ),
            ],
          )
        : Row(
            children: [
              Opacity(
                opacity: widget.enabled ? 1 : .5,
                child: SkeuSwitch(
                  value: _internalToggle,
                  width: 52,
                  height: 28,
                  onChanged: widget.enabled ? (_) => _handleToggle() : null,
                ),
              ),
              if (widget.label.trim().isNotEmpty) const SizedBox(width: 8),
              if (widget.label.trim().isNotEmpty)
                Text(
                  widget.label,
                  style:
                      widget.labelStyle ??
                      SkeuText.body(color: SkeuColors.inkSoft),
                ),
            ],
          );
  }
}
