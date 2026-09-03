import 'package:flutter/material.dart';
import 'package:wowcare/redesign/core/constants/app_sizes.dart';
import 'package:wowcare/redesign/core/theme/app_motion.dart';

/// The one press effect in the app.
///
/// Every tap feedback in this design is the same physical idea: the thing you
/// touched sinks a fixed number of logical pixels and settles back. Two
/// recipes:
///
/// * [Pressable.surface] sinks 2px and shrinks almost imperceptibly. Rows,
///   cards, chips, nav destinations: anything tappable that is not a rimmed
///   key.
/// * [Pressable.key] sinks 3px with no shrink. A rimmed key's 4px rim
///   *collapses* to 1px under the press, a 3px net travel, so the face must
///   not also shrink or the rim tears away from it.
///
/// A surface with a **static** rim that does not animate takes
/// [Pressable.surface] even though it has one: sinking 2px lands its face
/// exactly on that rim, which is the effect. 3px would carry it a pixel past.
///
/// The sink is in logical pixels deliberately. A fractional slide offset would
/// sink a 40px row half a pixel and a 400px card nearly five; the design calls
/// for the same distance everywhere.
///
/// A rimmed key needs to redraw as it sinks: its rim collapses in step with
/// the travel so the rim's bottom edge stays put. Pass a [builder] instead of a
/// [child] and it receives the press progress, 0 at rest and 1 at full press,
/// on every frame of the sink.
class Pressable extends StatefulWidget {
  const Pressable({
    this.child,
    this.builder,
    this.onTap,
    this.onLongPress,
    this.sink = AppSizes.surfaceSink,
    this.scale = AppSizes.surfacePressScale,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  }) : assert(
         (child == null) != (builder == null),
         'Pass exactly one of child or builder.',
       );

  /// Rows, cards, chips: sink 2px and shrink almost imperceptibly.
  const Pressable.surface({
    this.child,
    this.builder,
    this.onTap,
    this.onLongPress,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  }) : assert(
         (child == null) != (builder == null),
         'Pass exactly one of child or builder.',
       ),
       sink = AppSizes.surfaceSink,
       scale = AppSizes.surfacePressScale;

  /// Rimmed keys and segmented tabs: sink 3px, no shrink.
  const Pressable.key({
    this.child,
    this.builder,
    this.onTap,
    this.onLongPress,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  }) : assert(
         (child == null) != (builder == null),
         'Pass exactly one of child or builder.',
       ),
       sink = AppSizes.keySink,
       scale = 1;

  /// A kiosk pad key, the deepest rim in the app.
  const Pressable.padKey({
    this.child,
    this.builder,
    this.onTap,
    this.onLongPress,
    this.behavior = HitTestBehavior.opaque,
    super.key,
  }) : assert(
         (child == null) != (builder == null),
         'Pass exactly one of child or builder.',
       ),
       sink = AppSizes.padKeySink,
       scale = 1;

  /// What sinks. Exactly one of this and [builder] is set.
  final Widget? child;

  /// Builds what sinks from the press progress, 0 at rest to 1 at full press.
  /// For surfaces that redraw as they travel, such as a rim collapsing.
  final Widget Function(BuildContext context, double t)? builder;

  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// How far the surface sinks, in logical pixels.
  final double sink;

  /// Scale at full press. 1 disables the shrink.
  final double scale;

  final HitTestBehavior behavior;

  /// Whether this responds to a tap at all. A dead key still draws, still
  /// occupies its place, and simply does not move.
  bool get isEnabled => onTap != null || onLongPress != null;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _isDown = false;

  void _setDown({required bool down}) {
    if (_isDown != down) setState(() => _isDown = down);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.isEnabled;

    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: enabled ? (_) => _setDown(down: true) : null,
      onTapUp: enabled ? (_) => _setDown(down: false) : null,
      onTapCancel: enabled ? () => _setDown(down: false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(end: _isDown ? 1 : 0),
        duration: AppMotion.press,
        curve: AppMotion.ease,
        builder: (context, t, child) {
          final sunk = Transform.translate(
            offset: Offset(0, widget.sink * t),
            child: child ?? widget.builder!(context, t),
          );
          if (widget.scale == 1) return sunk;
          return Transform.scale(
            scale: 1 - (1 - widget.scale) * t,
            child: sunk,
          );
        },
        child: widget.child,
      ),
    );
  }
}
