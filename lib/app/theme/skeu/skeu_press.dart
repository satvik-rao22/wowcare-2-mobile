import 'package:flutter/material.dart';

import 'skeu_tokens.dart';

/// The one press effect in the app.
///
/// v2 of the design collapsed every tap feedback onto a single physical idea:
/// the thing you touched sinks a fixed 2 to 3 logical pixels and settles back.
/// Two recipes, both taken straight from the design's `style-active` rules:
///
/// * [SkeuPressable.surface] — `translateY(2px) scale(.995)`. Rows, cards,
///   wells, nav destinations, checkboxes, chips: anything tappable that is not
///   a rimmed key.
/// * [SkeuPressable.key] — `translateY(3px)`, no scale. Rimmed keys and
///   segmented-tab segments whose rim *collapses* under the press (4px to 1px,
///   a 3px net travel), so they must not also shrink.
///
/// A surface with a **static** rim — the 2px under-edge on a fold key or a
/// selected filter chip, which does not animate — takes [SkeuPressable.surface]
/// even though it has a rim: sinking 2px lands its face exactly on that rim,
/// which is the whole effect. Sinking 3px would carry it a pixel past.
///
/// The sink is in logical pixels on purpose. The v1 implementation used a
/// fractional [AnimatedSlide] offset, so a 40px row sank half a pixel while a
/// 400px card sank nearly five — the design explicitly calls for the same
/// distance everywhere.
class SkeuPressable extends StatefulWidget {
  const SkeuPressable({
    required this.child,
    this.onTap,
    this.onLongPress,
    this.sink = 2,
    this.scale = .995,
    super.key,
  });

  /// Non-key tappable surfaces: sink 2px and shrink almost imperceptibly.
  const SkeuPressable.surface({
    required this.child,
    this.onTap,
    this.onLongPress,
    super.key,
  }) : sink = 2,
       scale = .995;

  /// Rimmed keys and tab segments: sink 3px, no scale.
  const SkeuPressable.key({
    required this.child,
    this.onTap,
    this.onLongPress,
    super.key,
  }) : sink = 3,
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
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _down ? 1 : 0),
        duration: SkeuMotion.press,
        curve: SkeuMotion.easeOut,
        builder: (context, t, child) => Transform.translate(
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
