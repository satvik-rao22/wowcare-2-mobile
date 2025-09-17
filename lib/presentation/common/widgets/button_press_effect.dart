import 'package:flutter/material.dart';

class PressEffectWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool isLoading;
  final Widget? loadingIndicator;
  final double scaleFactor;
  final Duration animationDuration;

  const PressEffectWrapper({
    super.key,
    required this.child,
    this.onPressed,
    this.onLongPress,
    this.isLoading = false,
    this.loadingIndicator,
    this.scaleFactor = 0.9,
    this.animationDuration = const Duration(milliseconds: 100),
  });

  @override
  State<PressEffectWrapper> createState() => _PressEffectWrapperState();
}

class _PressEffectWrapperState extends State<PressEffectWrapper> {
  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => isPressed = true),
      onTapUp: (_) => setState(() => isPressed = false),
      onTapCancel: () => setState(() => isPressed = false),
      onTap: widget.isLoading ? null : widget.onPressed,
      onLongPress: widget.isLoading ? null : widget.onLongPress,
      child: AnimatedScale(
        scale: isPressed ? widget.scaleFactor : 1.0,
        duration: widget.animationDuration,
        child: widget.isLoading
            ? widget.loadingIndicator ??
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
            : widget.child,
      ),
    );
  }
}

