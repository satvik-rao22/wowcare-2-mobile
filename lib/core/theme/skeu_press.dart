/// The one press effect in the app.
///
/// Ported from the skeuomorphic kit on `wowcare-skeumorph`. Every tap feedback
/// in the flat material is the same physical idea: the thing you touched sinks
/// a fixed distance and settles back. Two recipes, straight from the design's
/// `style-active` rules:
///
/// * [SkeuPressable.surface] — sink 2px, shrink to .995. Rows, cards, wells,
///   nav destinations, checkboxes, chips: anything tappable that is not a
///   rimmed key.
/// * [SkeuPressable.key] — sink 3px, no scale. Rimmed keys and segmented-tab
///   segments, whose rim *collapses* under the press (4px to 1px, a 3px net
///   travel), so they must not also shrink.
///
/// A surface with a **static** rim — one that does not animate — takes
/// [SkeuPressable.surface] even though it has a rim: sinking 2px lands its
/// face exactly on that rim, which is the whole effect. Sinking 3px would
/// carry it a pixel past.
///
/// The sink is in logical pixels on purpose. A fractional offset would make a
/// 40px row sink half a pixel while a 400px card sank nearly five; the design
/// calls for the same distance everywhere.
library;

import 'package:flutter/widgets.dart';
import 'package:wowcare/core/theme/app_radius.dart';
import 'package:wowcare/core/theme/app_surfaces.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// Sinks its child while pressed. Purely visual: [onTap] and [onLongPress]
/// behave exactly as they would on a [GestureDetector].
class SkeuPressable extends StatefulWidget {
  const SkeuPressable({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.sink = AppMotion.pressTravelSurface,
    this.scale = .995,
    super.key,
  });

  /// Non-key tappable surfaces: sink 2px and shrink almost imperceptibly.
  const SkeuPressable.surface({
    required this.child,
    this.onTap,
    this.onLongPress,
    super.key,
  }) : sink = AppMotion.pressTravelSurface,
       scale = .995;

  /// Rimmed keys and tab segments: sink 3px, no scale.
  const SkeuPressable.key({
    required this.child,
    this.onTap,
    this.onLongPress,
    super.key,
  }) : sink = AppMotion.pressTravel,
       scale = 1;

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// How far the surface sinks, in logical pixels.
  final double sink;

  /// Scale at full press. 1 disables the shrink.
  final double scale;

  @override
  State<SkeuPressable> createState() => _SkeuPressableState();
}

class _SkeuPressableState extends State<SkeuPressable> {
  bool _down = false;

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final bool enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _down ? 1 : 0),
        duration: AppMotion.press,
        curve: AppMotion.easeOut,
        builder: (BuildContext context, double t, Widget? child) =>
            Transform.translate(
              offset: Offset(0, widget.sink * t),
              child: widget.scale == 1
                  ? child
                  : Transform.scale(
                      scale: 1 - (1 - widget.scale) * t,
                      child: child,
                    ),
            ),
        child: widget.child,
      ),
    );
  }
}

/// A key that is actually depressed when you press it.
///
/// [SkeuPressable] on its own cannot do this. A key's rim *is* a shadow on
/// the key's own decoration, so translating the whole widget carries the rim
/// down with the face and nothing appears to move. The rim has to stay where
/// it is while the face descends onto it, which takes both halves at once:
///
/// * the face translates down [AppMotion.pressTravel] (3 px), and
/// * the decoration swaps to [AppSurfaces.keyPressed], whose rim is 1 px
///   instead of 4.
///
/// 3 down plus 3 off the rim means the *bottom edge of the key does not
/// move*: only the face travels, onto the rim, which is what being pressed
/// looks like. Releasing reverses it over [AppMotion.press], 90 ms.
///
/// The press is watched with a [Listener], not a [GestureDetector], so it
/// takes no part in the gesture arena: whatever the child does with taps —
/// a `TextButton`, an `InkWell`, a `GestureDetector` — still happens.
class SkeuKeyBox extends StatefulWidget {
  const SkeuKeyBox({
    required this.variant,
    this.child,
    this.radius = AppRadius.lg,
    this.borderRadius,
    this.enabled = true,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.alignment,
    super.key,
  });

  final KeyVariant variant;

  /// Optional: a key can be a bare shape — a progress bar's filled track,
  /// a decorative rule — with nothing to press.
  final Widget? child;
  final double radius;
  final BorderRadius? borderRadius;

  /// A disabled key does not respond. Pass the variant you want painted;
  /// this only governs whether the press animates.
  final bool enabled;

  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final AlignmentGeometry? alignment;

  @override
  State<SkeuKeyBox> createState() => _SkeuKeyBoxState();
}

class _SkeuKeyBoxState extends State<SkeuKeyBox> {
  bool _down = false;

  void _set(bool down) {
    if (!widget.enabled || _down == down) return;
    setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final bool pressed = _down && widget.enabled;
    // A rimmed key travels the 3px its rim collapses by. A secondary key has
    // no rim, so it takes the 2px a plain tappable surface does.
    final double travel = switch (widget.variant) {
      KeyVariant.secondary ||
      KeyVariant.disabled => AppMotion.pressTravelSurface,
      _ => AppMotion.pressTravel,
    };
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedContainer(
        duration: AppMotion.press,
        curve: AppMotion.easeOut,
        transform: Matrix4.translationValues(0, pressed ? travel : 0, 0),
        width: widget.width,
        height: widget.height,
        margin: widget.margin,
        padding: widget.padding,
        alignment: widget.alignment,
        decoration: pressed
            ? AppSurfaces.keyPressed(
                widget.variant,
                radius: widget.radius,
                borderRadius: widget.borderRadius,
              )
            : AppSurfaces.key(
                widget.variant,
                radius: widget.radius,
                borderRadius: widget.borderRadius,
              ),
        child: widget.child,
      ),
    );
  }
}
