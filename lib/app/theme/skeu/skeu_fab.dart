import 'dart:async';

import 'package:flutter/material.dart';

import 'skeu_button.dart';
import 'skeu_inner_shadow.dart';
import 'skeu_tokens.dart';

/// The app's one floating action key.
///
/// v2 of the design replaced the scattered add buttons with a single FAB
/// pattern, and gave it three motions:
///
/// * **`fabIn`** — it arrives once, springing up from `scale(.3)` 26px below,
///   overshooting to `scale(1.13)` at 62% before settling.
/// * **`fabGlow`** — a breathing invitation glow behind it, a coloured drop
///   shadow that pulses between `opacity .3 / scale .9` and
///   `opacity .8 / scale 1.06` every 3.6s, starting after a 1s beat.
/// * the press, which is the same rim collapse as every other key: it sinks 3px
///   as its 4px rim closes to 1px.
///
/// Pair it with [SkeuFabConfirmation] inside a [SkeuFabDock] to get the
/// "record landed" confirmation the design shows.
class SkeuFab extends StatefulWidget {
  const SkeuFab({
    required this.icon,
    this.onTap,
    this.tooltip,
    this.variant = SkeuButtonVariant.pink,
    this.size = 60,
    this.radius = 22,
    this.iconSize = 26,
    this.animateIn = true,
    this.glow = true,
    super.key,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;

  /// Pink by default: adding is THE recommended action on the screens that
  /// carry a FAB.
  final SkeuButtonVariant variant;

  final double size;
  final double radius;
  final double iconSize;

  /// Plays `fabIn` on first build. Turn off when the key is already on screen
  /// and only its icon changes.
  final bool animateIn;

  /// Plays the breathing `fabGlow`. Turn off for a destructive or secondary
  /// action, which should not invite a tap.
  final bool glow;

  @override
  State<SkeuFab> createState() => _SkeuFabState();
}

class _SkeuFabState extends State<SkeuFab> with TickerProviderStateMixin {
  late final AnimationController _entrance;
  late final AnimationController _breath;
  Timer? _glowDelay;
  bool _down = false;

  /// `fabIn`: 0% scale .3, 62% scale 1.13, 100% scale 1.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: .3, end: 1.13), weight: 62),
    TweenSequenceItem(tween: Tween(begin: 1.13, end: 1), weight: 38),
  ]).animate(_entrance);

  /// `fabIn`: 0% translateY 26px, settled by 62%.
  late final Animation<double> _rise = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 26.0, end: 0.0), weight: 62),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 38),
  ]).animate(_entrance);

  /// `fabIn`: opacity 0 -> 1 by 62%.
  late final Animation<double> _fade = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 62),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 38),
  ]).animate(_entrance);

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: SkeuMotion.fabIn,
      value: widget.animateIn ? 0 : 1,
    );
    if (widget.animateIn) _entrance.forward();

    // reverse:true halves the period, so one full breath is 2 x 1.8s = 3.6s.
    _breath = AnimationController(
      vsync: this,
      duration: SkeuMotion.glowCycle ~/ 2,
    );
    if (widget.glow) {
      _glowDelay = Timer(SkeuMotion.glowDelay, () {
        if (mounted) _breath.repeat(reverse: true);
      });
    }
  }

  @override
  void didUpdateWidget(SkeuFab old) {
    super.didUpdateWidget(old);
    if (widget.glow == old.glow) return;
    if (widget.glow) {
      _breath.repeat(reverse: true);
    } else {
      _breath.stop();
      _breath.value = 0;
    }
  }

  @override
  void dispose() {
    _glowDelay?.cancel();
    _entrance.dispose();
    _breath.dispose();
    super.dispose();
  }

  void _set(bool down) {
    if (_down != down) setState(() => _down = down);
  }

  @override
  Widget build(BuildContext context) {
    final skin = skeuKeySkin(widget.variant);
    final enabled = widget.onTap != null;
    final depth = _down
        ? SkeuElevation.rimDepthPressed
        : SkeuElevation.rimDepth;
    final br = BorderRadius.circular(widget.radius);

    // The breathing invitation glow: a coloured drop shadow on an inset,
    // slightly smaller box behind the key. Never hit-tests.
    final glow = IgnorePointer(
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedBuilder(
          animation: _breath,
          builder: (context, _) {
            final t = Curves.easeInOut.transform(_breath.value);
            return Opacity(
              opacity: .3 + .5 * t,
              child: Transform.scale(
                scale: .9 + .16 * t,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(widget.radius - 2),
                    boxShadow: [
                      BoxShadow(
                        color: skin.glow.withValues(alpha: .7),
                        offset: const Offset(0, 12),
                        blurRadius: 26,
                        spreadRadius: -8,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );

    Widget key = AnimatedContainer(
      duration: SkeuMotion.press,
      curve: SkeuMotion.easeOut,
      width: widget.size,
      height: widget.size,
      transform: Matrix4.translationValues(
        0,
        SkeuElevation.rimDepth - depth,
        0,
      ),
      decoration: BoxDecoration(
        gradient: skin.face,
        borderRadius: br,
        boxShadow: [BoxShadow(color: skin.rim, offset: Offset(0, depth))],
      ),
      child: SkeuInnerShadow(
        shadows: SkeuElevation.bevelTopSoft,
        borderRadius: br,
        child: Center(
          child: Icon(widget.icon, size: widget.iconSize, color: skin.label),
        ),
      ),
    );

    key = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap,
      child: key,
    );

    if (widget.tooltip != null) {
      key = Tooltip(message: widget.tooltip!, child: key);
    }

    return AnimatedBuilder(
      animation: _entrance,
      builder: (context, child) => Opacity(
        opacity: _fade.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, _rise.value),
          child: Transform.scale(scale: _scale.value, child: child),
        ),
      ),
      child: SizedBox(
        // The rim needs room below the face, as it does on every key.
        width: widget.size,
        height: widget.size + SkeuElevation.rimDepth,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            Positioned.fill(bottom: SkeuElevation.rimDepth, child: glow),
            key,
          ],
        ),
      ),
    );
  }
}

/// The "record landed" confirmation that pops in above a [SkeuFab].
///
/// Mount it to show it; the `confirmPop` spring plays on the way in. The caller
/// owns how long it stays — see [SkeuFabDock] for the usual pattern.
class SkeuFabConfirmation extends StatefulWidget {
  const SkeuFabConfirmation({
    required this.label,
    this.icon = Icons.check_rounded,
    this.tone = SkeuSurfaces.faceGreenColor,
    super.key,
  });

  final String label;
  final IconData icon;

  /// The colour of the round badge. Green by default: something landed.
  final Color tone;

  @override
  State<SkeuFabConfirmation> createState() => _SkeuFabConfirmationState();
}

class _SkeuFabConfirmationState extends State<SkeuFabConfirmation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pop = AnimationController(
    vsync: this,
    duration: SkeuMotion.confirmPop,
  )..forward();

  /// `confirmPop`: 0% scale .6 / translateY 10px / opacity 0, 58% scale 1.06,
  /// 100% scale 1.
  late final Animation<double> _scale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: .6, end: 1.06), weight: 58),
    TweenSequenceItem(tween: Tween(begin: 1.06, end: 1), weight: 42),
  ]).animate(_pop);

  late final Animation<double> _rise = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 10.0, end: 0.0), weight: 58),
    TweenSequenceItem(tween: ConstantTween(0.0), weight: 42),
  ]).animate(_pop);

  late final Animation<double> _fade = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 58),
    TweenSequenceItem(tween: ConstantTween(1.0), weight: 42),
  ]).animate(_pop);

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _pop,
    builder: (context, child) => Opacity(
      opacity: _fade.value.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, _rise.value),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
    ),
    child: Container(
      height: 42,
      padding: const EdgeInsets.only(left: 11, right: 16),
      decoration: BoxDecoration(
        gradient: SkeuSurfaces.card,
        borderRadius: BorderRadius.circular(SkeuRadius.pill),
        boxShadow: SkeuElevation.elev3,
      ),
      child: SkeuInnerShadow(
        shadows: SkeuElevation.bevelFull,
        borderRadius: BorderRadius.circular(SkeuRadius.pill),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: widget.tone,
                shape: BoxShape.circle,
              ),
              child: SkeuInnerShadow(
                shadows: SkeuElevation.bevelTopSoft,
                borderRadius: BorderRadius.circular(13),
                child: Center(
                  child: Icon(widget.icon, size: 16, color: SkeuColors.white),
                ),
              ),
            ),
            const SizedBox(width: 9),
            Text(
              widget.label,
              style: SkeuText.small(
                color: SkeuColors.ink,
                weight: SkeuText.weightBold,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// Stacks a [SkeuFab] under its confirmation, 12px apart, the way the design
/// draws the pair.
///
/// Prefer handing this to `Scaffold.floatingActionButton` (the default
/// `endFloating` location already clears a `bottomNavigationBar`, and it stays
/// correct whatever height that bar reports). Use [SkeuFabDock.stacked] only
/// when you are positioning the dock inside a [Stack] yourself, where the
/// design's own bottom-right inset applies.
class SkeuFabDock extends StatelessWidget {
  const SkeuFabDock({
    required this.fab,
    this.confirmation,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// For manual placement in a [Stack]: the design's `right:18px; bottom:98px`,
  /// which clears a nav bar inset 8px from the bottom of a 844px screen.
  const SkeuFabDock.stacked({required this.fab, this.confirmation, super.key})
    : padding = const EdgeInsets.only(right: 18, bottom: 98);

  final Widget fab;

  /// The confirmation pill, or null when nothing has just landed. Mounting it
  /// plays its pop.
  final Widget? confirmation;

  /// Extra inset around the dock. Zero by default, because `Scaffold` already
  /// positions a floating action button clear of the bottom nav bar.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (confirmation != null) ...[
          confirmation!,
          const SizedBox(height: 12),
        ],
        fab,
      ],
    ),
  );
}
