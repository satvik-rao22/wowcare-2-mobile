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
