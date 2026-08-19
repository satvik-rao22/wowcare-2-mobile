import 'package:flutter/material.dart';
import 'package:wowcare/app/theme/skeu/skeu.dart';

/// The app's "add" key.
///
/// A rimmed pink key in the skeuomorphic language — pink because adding is the
/// recommended action on the screens that show this. It sinks onto its rim when
/// pressed, like every other key in the app. Sizes still follow the caller's
/// tablet flags so existing layouts are unchanged.
class GradientAddButton extends StatefulWidget {
  final VoidCallback? onTap;
  final double? size;
  final double? iconSize;
  final double? borderRadius;
  final double? wantedButtonSize;
  final bool isTablet;
  final bool isLargeTablet;
  final bool isRectangle;

  /// Renders the key dead (neutral, no rim glow) instead of pink. [onTap] still
  /// fires, so the caller can explain why it's unavailable (e.g. a tooltip).
  final bool isDisabled;

  const GradientAddButton({
    Key? key,
    this.onTap,
    this.size,
    this.iconSize,
    this.borderRadius,
    this.isTablet = false,
    this.isRectangle = true,
    this.isLargeTablet = false,
    this.wantedButtonSize,
    this.isDisabled = false,
  }) : super(key: key);

  @override
  State<GradientAddButton> createState() => _GradientAddButtonState();
}

class _GradientAddButtonState extends State<GradientAddButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    // Calculate responsive dimensions
    final buttonSize =
        widget.size ??
        (widget.isLargeTablet
            ? 72.0
            : widget.isTablet
            ? 56.0
            : 40.0);
    final buttonIconSize =
        widget.iconSize ??
        (widget.isLargeTablet
            ? 32.0
            : widget.isTablet
            ? 24.0
            : 20.0);
    final buttonBorderRadius =
        widget.borderRadius ??
        (widget.isLargeTablet
            ? 16.0
            : widget.isTablet
            ? 12.0
            : 8.0);

    final dead = widget.isDisabled || widget.onTap == null;
    final depth = _down
        ? SkeuElevation.rimDepthPressed
        : SkeuElevation.rimDepth;
    final side = widget.wantedButtonSize ?? buttonSize;
    final br = widget.isRectangle
        ? BorderRadius.circular(buttonBorderRadius)
        : BorderRadius.circular(side);

    final key = AnimatedContainer(
      duration: SkeuMotion.press,
      curve: SkeuMotion.easeOut,
      width: side,
      height: side,
      transform: Matrix4.translationValues(
        0,
        SkeuElevation.rimDepth - depth,
        0,
      ),
      decoration: BoxDecoration(
        gradient: dead ? SkeuSurfaces.faceNeutral : SkeuSurfaces.facePink,
        borderRadius: br,
        boxShadow: [
          BoxShadow(
            color: dead ? SkeuElevation.rimNeutral : SkeuElevation.rimPink,
            offset: Offset(0, depth),
          ),
          if (!dead)
            BoxShadow(
              color: SkeuColors.pink800.withValues(alpha: .5),
              offset: Offset(0, _down ? 5 : 10),
              blurRadius: _down ? 12 : 18,
              spreadRadius: -8,
            ),
        ],
      ),
      // No gloss layer: the v2 flat pass removed `--gloss-top` entirely.
      child: Center(
        child: Icon(
          Icons.add_rounded,
          color: dead ? SkeuColors.inkFaint : SkeuColors.white,
          size: buttonIconSize,
        ),
      ),
    );

    if (widget.onTap == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: SkeuElevation.rimDepth),
        child: key,
      );
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: widget.onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: SkeuElevation.rimDepth),
        child: key,
      ),
    );
  }
}
