import 'package:flutter/material.dart';

import 'skeu_inner_shadow.dart';
import 'skeu_tokens.dart';

/// The material of a pressable key.
///
/// Pink is THE recommended action and must never double as a warning; teal is
/// structure and secondary actions; neutral is the quiet third option.
enum SkeuButtonVariant { pink, teal, sun, green, orange, navy, neutral, danger }

/// A rimmed key you push down onto.
///
/// Each variant is a solid brand-coloured face with a specular gloss, sitting
/// on a 4px solid rim of its own darker shade. On press the key sinks onto the
/// rim (`--rim-depth` 4px -> `--rim-depth-pressed` 1px) and the ambient glow
/// tightens, which is the whole illusion: something physical moved.
class SkeuButton extends StatefulWidget {
  const SkeuButton({
    required this.label,
    this.onPressed,
    this.variant = SkeuButtonVariant.pink,
    this.icon,
    this.trailingIcon,
    this.height = 54,
    this.radius = SkeuRadius.pill,
    this.width,
    this.expand = true,
    this.isLoading = false,
    this.enabled = true,
    this.fontSize = 16,
    this.padding,
    this.child,
    super.key,
  });

  /// A compact key for inline use — chips of action inside a card.
  const SkeuButton.small({
    required String label,
    VoidCallback? onPressed,
    SkeuButtonVariant variant = SkeuButtonVariant.teal,
    IconData? icon,
    bool enabled = true,
    bool isLoading = false,
    Key? key,
  }) : this(
         label: label,
         onPressed: onPressed,
         variant: variant,
         icon: icon,
         enabled: enabled,
         isLoading: isLoading,
         height: 40,
         fontSize: 14,
         expand: false,
         padding: const EdgeInsets.symmetric(horizontal: 18),
         key: key,
       );

  final String label;
  final VoidCallback? onPressed;
  final SkeuButtonVariant variant;
  final IconData? icon;
  final IconData? trailingIcon;
  final double height;
  final double radius;
  final double? width;
  final bool expand;
  final bool isLoading;
  final bool enabled;
  final double fontSize;
  final EdgeInsetsGeometry? padding;

  /// Replaces [label] and [icon] with arbitrary content, still on the same
  /// rimmed face. For callers that pass a composed row rather than a string.
  final Widget? child;

  @override
  State<SkeuButton> createState() => _SkeuButtonState();
}

class _SkeuButtonState extends State<SkeuButton> {
  bool _down = false;

  bool get _interactive =>
      widget.enabled && !widget.isLoading && widget.onPressed != null;

  ({Gradient face, Color rim, Color glow, Color label}) get _skin =>
      switch (widget.variant) {
        SkeuButtonVariant.pink => (
          face: SkeuSurfaces.facePink,
          rim: SkeuElevation.rimPink,
          glow: const Color(0xFF8E0E3A),
          label: SkeuColors.white,
        ),
        SkeuButtonVariant.teal => (
          face: SkeuSurfaces.faceTeal,
          rim: SkeuElevation.rimTeal,
          glow: const Color(0xFF186265),
          label: SkeuColors.white,
        ),
        SkeuButtonVariant.sun => (
          face: SkeuSurfaces.faceSun,
          rim: SkeuElevation.rimSun,
          glow: const Color(0xFFD3790C),
          label: SkeuColors.sun800,
        ),
        SkeuButtonVariant.green => (
          face: SkeuSurfaces.faceGreen,
          rim: SkeuElevation.rimGreen,
          glow: const Color(0xFF0C7143),
          label: SkeuColors.white,
        ),
        SkeuButtonVariant.orange => (
          face: SkeuSurfaces.faceOrange,
          rim: SkeuColors.orange600,
          glow: SkeuColors.orange600,
          label: SkeuColors.white,
        ),
        SkeuButtonVariant.navy => (
          face: SkeuSurfaces.faceNavy,
          rim: SkeuElevation.rimNavy,
          glow: SkeuColors.navy900,
          label: SkeuColors.white,
        ),
        SkeuButtonVariant.neutral => (
          face: SkeuSurfaces.faceNeutral,
          rim: SkeuElevation.rimNeutral,
          glow: SkeuColors.navy,
          label: SkeuColors.ink,
        ),
        SkeuButtonVariant.danger => (
          face: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE8574C), Color(0xFFD92D20), Color(0xFFCB2A1E)],
            stops: [0, .52, 1],
          ),
          rim: SkeuColors.danger600,
          glow: SkeuColors.danger600,
          label: SkeuColors.white,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final skin = _skin;
    final br = BorderRadius.circular(widget.radius);
    final depth = _down
        ? SkeuElevation.rimDepthPressed
        : SkeuElevation.rimDepth;
    final isNeutral = widget.variant == SkeuButtonVariant.neutral;

    Widget face = AnimatedContainer(
      duration: SkeuMotion.press,
      curve: SkeuMotion.easeOut,
      height: widget.height,
      width: widget.expand ? double.infinity : widget.width,
      transform: Matrix4.translationValues(
        0,
        SkeuElevation.rimDepth - depth,
        0,
      ),
      decoration: BoxDecoration(
        gradient: skin.face,
        borderRadius: br,
        boxShadow: [
          // The solid rim you press away.
          BoxShadow(color: skin.rim, offset: Offset(0, depth)),
          // Ambient coloured glow, tightening as the key sinks.
          BoxShadow(
            color: skin.glow.withValues(alpha: isNeutral ? .3 : .5),
            offset: Offset(0, _down ? 5 : 10),
            blurRadius: _down ? 12 : 18,
            spreadRadius: -8,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            // Specular highlight over the coloured face.
            Positioned.fill(
              child: IgnorePointer(
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: SkeuSurfaces.glossTop,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SkeuInsetPainter(
                    isNeutral
                        ? SkeuElevation.bevelTop
                        : SkeuElevation.bevelTopSoft,
                    br,
                  ),
                ),
              ),
            ),
            Padding(
              padding:
                  widget.padding ?? const EdgeInsets.symmetric(horizontal: 20),
              child: Center(child: _buildLabel(skin.label)),
            ),
          ],
        ),
      ),
    );

    if (!_interactive) {
      face = Opacity(opacity: widget.enabled ? 1 : .45, child: face);
    }

    // The rim lives below the face, so reserve its full depth in layout to
    // stop the button shifting the rows around it as it sinks.
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _interactive ? (_) => setState(() => _down = true) : null,
      onTapUp: _interactive ? (_) => setState(() => _down = false) : null,
      onTapCancel: _interactive ? () => setState(() => _down = false) : null,
      onTap: _interactive ? widget.onPressed : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: SkeuElevation.rimDepth),
        child: face,
      ),
    );
  }

  Widget _buildLabel(Color color) {
    if (widget.child != null && !widget.isLoading) {
      return DefaultTextStyle.merge(
        style: TextStyle(
          fontFamily: SkeuText.family,
          fontSize: widget.fontSize,
          fontWeight: SkeuText.weightBold,
          color: color,
        ),
        child: IconTheme.merge(
          data: IconThemeData(color: color, size: widget.fontSize + 3),
          child: widget.child!,
        ),
      );
    }
    if (widget.isLoading) {
      return SizedBox(
        height: widget.fontSize + 4,
        width: widget.fontSize + 4,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(color),
        ),
      );
    }
    final text = Text(
      widget.label,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: SkeuText.family,
        fontSize: widget.fontSize,
        fontWeight: SkeuText.weightBold,
        color: color,
        letterSpacing: widget.fontSize * .01,
      ),
    );
    if (widget.icon == null && widget.trailingIcon == null) return text;
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.icon != null) ...[
          Icon(widget.icon, size: widget.fontSize + 3, color: color),
          const SizedBox(width: 9),
        ],
        Flexible(child: text),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 9),
          Icon(widget.trailingIcon, size: widget.fontSize + 3, color: color),
        ],
      ],
    );
  }
}

/// A raised square key holding a single icon — back buttons, header actions,
/// tile affordances. `--surface-raised` on `--elev-1` with a full bevel.
class SkeuIconButton extends StatelessWidget {
  const SkeuIconButton({
    required this.icon,
    this.onPressed,
    this.size = 44,
    this.iconSize = 20,
    this.radius = 15,
    this.gradient,
    this.iconColor = SkeuColors.ink,
    this.badgeCount,
    this.tooltip,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final double size;
  final double iconSize;
  final double radius;
  final Gradient? gradient;
  final Color iconColor;

  /// Optional unread pip, drawn as a pink bead on the top-right corner.
  final int? badgeCount;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final br = BorderRadius.circular(radius);
    Widget key = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: gradient ?? SkeuSurfaces.raised,
        borderRadius: br,
        boxShadow: SkeuElevation.elev1,
      ),
      child: ClipRRect(
        borderRadius: br,
        child: Stack(
          children: [
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SkeuInsetPainter(SkeuElevation.bevelFull, br),
                ),
              ),
            ),
            Center(
              child: Icon(icon, size: iconSize, color: iconColor),
            ),
          ],
        ),
      ),
    );

    if (badgeCount != null && badgeCount! > 0) {
      key = Stack(
        clipBehavior: Clip.none,
        children: [
          key,
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              constraints: const BoxConstraints(minWidth: 18),
              decoration: BoxDecoration(
                gradient: SkeuSurfaces.facePink,
                borderRadius: BorderRadius.circular(SkeuRadius.pill),
                border: Border.all(color: SkeuColors.white, width: 1.5),
                boxShadow: SkeuElevation.shadowChip,
              ),
              child: Text(
                badgeCount! > 99 ? '99+' : '$badgeCount',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: SkeuText.family,
                  fontSize: 10,
                  fontWeight: SkeuText.weightBold,
                  color: SkeuColors.white,
                  height: 1.2,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (onPressed != null) {
      key = _PressSink(onTap: onPressed!, child: key);
    }
    if (tooltip != null) key = Tooltip(message: tooltip!, child: key);
    return key;
  }
}

/// A quiet text action — "Forgot Password?", "View all", "Skip". No rim; it is
/// deliberately not an object, so it cannot compete with a real key.
class SkeuTextButton extends StatelessWidget {
  const SkeuTextButton({
    required this.label,
    this.onPressed,
    this.color = SkeuColors.ink,
    this.fontSize = 14,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final double fontSize;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onPressed,
    child: Padding(
      padding: padding,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 3, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: SkeuText.family,
              fontSize: fontSize,
              fontWeight: SkeuText.weightHeading,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class _PressSink extends StatefulWidget {
  const _PressSink({required this.onTap, required this.child});

  final VoidCallback onTap;
  final Widget child;

  @override
  State<_PressSink> createState() => _PressSinkState();
}

class _PressSinkState extends State<_PressSink> {
  bool _down = false;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTapDown: (_) => setState(() => _down = true),
    onTapUp: (_) => setState(() => _down = false),
    onTapCancel: () => setState(() => _down = false),
    onTap: widget.onTap,
    child: AnimatedScale(
      scale: _down ? .93 : 1,
      duration: SkeuMotion.press,
      child: widget.child,
    ),
  );
}
