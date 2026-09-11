part of 'message_bubble_widget.dart';

// Text/HTML and reaction helper widgets for [MessageBubble] (Mandate 6 split
// from message_bubble_parts.dart). A `part` file: library-private, shares the
// parent's imports, pure move with no behaviour change.

// Wraps html.Html so each mounted instance owns its own _anchorKey GlobalKey.
// flutter_html creates a HtmlParser(key: _anchorKey) inside _HtmlState.build().
// If _anchorKey is shared (e.g. via MessageBubble State fields) and the same
// widget tree is mounted in two places simultaneously (original bubble + the
// reactions-dialog preview), two HtmlParser widgets get the same GlobalKey →
// crash. Owning the key in THIS State means each placement gets its own key.
class _StableHtml extends StatefulWidget {
  final String data;
  final Map<String, html.Style> style;

  /// Called when a link (`<a href>`) inside the HTML is tapped.
  final void Function(String? href)? onLinkTap;

  /// Color used for `<a>` tags. Defaults to [AppColors.primaryColor].
  final Color? linkColor;

  const _StableHtml({
    super.key,
    required this.data,
    required this.style,
    this.onLinkTap,
    this.linkColor,
  });

  @override
  State<_StableHtml> createState() => _StableHtmlState();
}

class _StableHtmlState extends State<_StableHtml> {
  final GlobalKey _anchorKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final linkColor = widget.linkColor ?? AppColors.primaryColor;

    // Merge caller styles with the <a> tag style so links are always
    // visually distinguishable (underlined, same color as message text).
    final mergedStyle = {
      ...widget.style,
      'a': html.Style(
        color: linkColor,
        textDecoration: TextDecoration.underline,
        textDecorationColor: linkColor,
        fontWeight: FontWeight.w600,
      ),
    };

    // Wrap with decoration:none to prevent the dialog context's DefaultTextStyle
    // (no Material/Scaffold wrapper in HeroDialogRoute) from leaking yellow
    // underlines into flutter_html's text span rendering.
    return DefaultTextStyle.merge(
      style: const TextStyle(decoration: TextDecoration.none),
      child: html.Html(
        anchorKey: _anchorKey,
        data: widget.data,
        style: mergedStyle,
        onLinkTap: widget.onLinkTap != null
            ? (url, _, __) => widget.onLinkTap!(url)
            : null,
      ),
    );
  }
}

// ── Double-tap heart floating overlay ────────────────────────────────────────

/// A ❤️ that floats at [center], springs to full size via [Curves.elasticOut],
/// holds briefly, then fades out. Lives in the root [Overlay] so it appears
/// on top of everything — no build-tree impact on [MessageBubble].
///
/// Lifecycle: the parent creates a fresh [AnimationController] per double-tap,
/// forwards it, and disposes it (plus removes the [OverlayEntry]) in the
/// controller's [AnimationStatus.completed] listener — zero leaks.
class _HeartFloatOverlay extends StatelessWidget {
  const _HeartFloatOverlay({required this.center, required this.controller});

  final Offset center;
  final AnimationController controller;

  @override
  Widget build(BuildContext context) {
    // Phase 1 (0–65 %): spring scale 0.2 → 1.4 with elastic overshoot.
    // Phase 2 (65–75 %): settle back to 1.0.
    // Phase 3 (75–100 %): hold at 1.0 while fading out.
    final scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.2,
          end: 1.4,
        ).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.4,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 10,
      ),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 25),
    ]).animate(controller);

    final opacityAnim = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 65),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 0.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 35,
      ),
    ]).animate(controller);

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) => Positioned(
        // Centre the 60×60 emoji on the bubble's midpoint.
        left: center.dx - 30,
        top: center.dy - 30,
        child: IgnorePointer(
          child: Opacity(
            opacity: opacityAnim.value.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scaleAnim.value,
              child: Text(
                '❤️',
                style: AppTextStyles.size16.copyWith(
                  fontSize: 50,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Telegram-style animated reaction badge ────────────────────────────────────

/// Compact emoji-reaction pill that animates each emoji independently:
///  • Added emoji  → spring scale 0.6 → 1.15 → 1.0  +  fade-in  (~300 ms)
///  • Removed emoji → shrink to 0.8  +  fade-out               (~200 ms)
///  • Existing emojis stay stable — no unnecessary rebuilds.
///
/// Flutter preserves widget State across [AnimatedBuilder] rebuilds (same
/// runtimeType + position in tree), so [didUpdateWidget] fires whenever the
/// parent passes new [counts], allowing per-emoji diff and targeted animation.
class _AnimatedReactionBadge extends StatefulWidget {
  const _AnimatedReactionBadge({
    required this.counts,
    this.onTap,
    this.onLongPress,
  });

  final Map<String, int> counts;

  /// Tap anywhere on the badge — shows who reacted (WhatsApp-style).
  final VoidCallback? onTap;

  /// Long-press anywhere on the badge — opens the reaction line to
  /// add/change/remove your own reaction.
  final VoidCallback? onLongPress;

  @override
  State<_AnimatedReactionBadge> createState() => _AnimatedReactionBadgeState();
}

class _AnimatedReactionBadgeState extends State<_AnimatedReactionBadge>
    with TickerProviderStateMixin {
  // Per-emoji animation controllers (scale + opacity share the same timeline).
  final Map<String, AnimationController> _controllers = {};

  // The counts currently rendered, which may include emojis still fading out.
  late Map<String, int> _displayed;

  @override
  void initState() {
    super.initState();
    _displayed = Map.from(widget.counts);
    for (final emoji in widget.counts.keys) {
      _ensureController(emoji, animate: false);
    }
  }

  // Mandate 2 (Bucket C): every setState in this badge (here and in
  // [_animateOut]) is tied to the per-emoji spring-in / shrink-out
  // AnimationControllers — animation lifecycle, so setState is the right tool.
  @override
  void didUpdateWidget(_AnimatedReactionBadge old) {
    super.didUpdateWidget(old);
    final prev = old.counts.keys.toSet();
    final next = widget.counts.keys.toSet();

    // Newly added emojis — spring in.
    for (final emoji in next.difference(prev)) {
      _ensureController(emoji, animate: true);
      setState(() => _displayed[emoji] = widget.counts[emoji]!);
    }

    // Removed emojis — shrink + fade out, then remove from display.
    for (final emoji in prev.difference(next)) {
      _animateOut(emoji);
    }

    // Count changes on existing emojis — update display immediately.
    for (final emoji in next.intersection(prev)) {
      if (old.counts[emoji] != widget.counts[emoji]) {
        setState(() => _displayed[emoji] = widget.counts[emoji]!);
      }
    }
  }

  void _ensureController(String emoji, {required bool animate}) {
    _controllers[emoji]?.dispose();
    final ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _controllers[emoji] = ctrl;
    if (animate) {
      ctrl.forward();
    } else {
      ctrl.value = 1.0;
    }
  }

  void _animateOut(String emoji) {
    final ctrl = _controllers[emoji];
    if (ctrl == null) {
      if (mounted) setState(() => _displayed.remove(emoji));
      return;
    }
    ctrl.duration = const Duration(milliseconds: 200);
    ctrl.reverse().then((_) {
      if (mounted) {
        setState(() {
          _displayed.remove(emoji);
          _controllers.remove(emoji)?.dispose();
        });
      }
    });
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_displayed.isEmpty) return const SizedBox.shrink();

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.blackColor.withValues(alpha: 0.12),
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final entry in _displayed.entries.take(3)) ...[
            _buildAnimatedEmoji(entry.key, entry.value),
            const SizedBox(width: 3),
          ],
        ],
      ),
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      child: badge,
    );
  }

  Widget _buildAnimatedEmoji(String emoji, int count) {
    final ctrl = _controllers[emoji];
    final chip = _EmojiChip(emoji: emoji, count: count);
    if (ctrl == null) return chip;

    // Add animation: spring 0.6 → 1.15 → 1.0 + fade-in.
    // Remove animation (ctrl reversed): same tween runs backward → shrink + fade.
    final scaleAnim = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 0.6,
          end: 1.15,
        ).chain(CurveTween(curve: Curves.easeOut)),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.15,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeIn)),
        weight: 30,
      ),
    ]).animate(ctrl);

    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, child) => Opacity(
        opacity: ctrl.value.clamp(0.0, 1.0),
        child: Transform.scale(scale: scaleAnim.value, child: child),
      ),
      child: chip,
    );
  }
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({required this.emoji, required this.count});

  final String emoji;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          emoji,
          style: AppTextStyles.size14.copyWith(
            decoration: TextDecoration.none,
            height: 1.2,
          ),
        ),
        if (count > 1) ...[
          const SizedBox(width: 2),
          Text(
            '$count',
            style: AppTextStyles.size14.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.messagingPreviewBody,
              decoration: TextDecoration.none,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }
}
