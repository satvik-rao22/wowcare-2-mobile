import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_colors.dart';

/// Wraps any list/card child and briefly flashes a highlight when it is the
/// target of a notification deep-link.
///
/// **Convention:** the destination screen receives a `highlightCode` (see
/// `NotificationRouteResolver` / the `highlightCode` query param) and forwards
/// it down the tree. Each card passes its own [code]. When [code] matches
/// [highlightCode] the card:
///   1. fires [onHighlighted] once after layout — so the enclosing list can
///      scroll the card into view, and
///   2. flashes a tinted border + fill that fades out over [duration].
///
/// When the codes don't match it renders [child] unchanged with zero overhead.
///
/// ```dart
/// HighlightableCard(
///   code: doc.documentCode,
///   highlightCode: widget.highlightCode,
///   onHighlighted: () => _scrollTo(index),
///   child: _DocumentCard(doc),
/// )
/// ```
class HighlightableCard extends StatefulWidget {
  const HighlightableCard({
    super.key,
    required this.child,
    required this.code,
    required this.highlightCode,
    this.onHighlighted,
    this.borderRadius = 14,
    this.highlightColor,
    this.duration = const Duration(milliseconds: 2200),
    this.scrollOnHighlight = false,
    this.foreground = false,
  });

  /// The card content.
  final Widget child;

  /// This card's identifier (studentCode, documentCode, shift_code, …).
  final String? code;

  /// The target code carried by the notification. Null when not deep-linked.
  final String? highlightCode;

  /// Fired once, after the first frame, when this card is the highlight target.
  /// Use it to scroll the card into view.
  final VoidCallback? onHighlighted;

  final double borderRadius;
  final Color? highlightColor;
  final Duration duration;

  /// When true, the card scrolls itself into view (via its own context) on
  /// highlight — no external [GlobalKey] needed. Use for deeply-nested cards.
  final bool scrollOnHighlight;

  /// Paints the flash IN FRONT of [child] instead of behind it.
  ///
  /// The default (behind) is invisible when the child paints its own opaque,
  /// full-bleed background — e.g. `StaffStyleCard`, an opaque white `Container`
  /// with no margin — because the child covers the exact same rect and hides
  /// both the border and the tint. Set this for such cards; the tint is
  /// translucent, so the content still reads through.
  final bool foreground;

  bool get _matches {
    final a = (code ?? '').trim();
    final b = (highlightCode ?? '').trim();
    return a.isNotEmpty && a.toUpperCase() == b.toUpperCase();
  }

  @override
  State<HighlightableCard> createState() => _HighlightableCardState();
}

class _HighlightableCardState extends State<HighlightableCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  /// The (code|highlightCode) pair we've already flashed for. Prevents the
  /// highlight from re-firing on every rebuild (e.g. each swipe of a bucket
  /// board) while the same deep-link highlightCode is still set.
  String? _flashedKey;

  String get _matchKey =>
      '${(widget.code ?? '').trim().toUpperCase()}|${(widget.highlightCode ?? '').trim().toUpperCase()}';

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    if (widget._matches) _trigger();
  }

  @override
  void didUpdateWidget(covariant HighlightableCard old) {
    super.didUpdateWidget(old);
    // Re-flash only when this card NEWLY becomes the target for a pair we
    // haven't flashed yet — e.g. the list finished loading and the matching row
    // only now exists, or a fresh notification points at a different code.
    // Crucially, do NOT re-flash on every rebuild (swipes/scroll) while the same
    // highlightCode is still set: gate on _flashedKey.
    if (widget._matches && _flashedKey != _matchKey) _trigger();
  }

  void _trigger() {
    _flashedKey = _matchKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // When the data is cached, the target card mounts synchronously DURING
      // the route/tab push transition — a flash started right now plays
      // off-screen and is missed, and the _flashedKey guard then blocks a
      // re-flash. Delay the start so it lands after the transition settles.
      // (On the uncached path the data arrives ~1s later anyway, so this small
      // delay is imperceptible there.)
      Future.delayed(const Duration(milliseconds: 350), () {
        if (!mounted) return;
        if (widget.scrollOnHighlight) {
          Scrollable.ensureVisible(
            context,
            duration: const Duration(milliseconds: 400),
            alignment: 0.1,
            curve: Curves.easeOut,
          );
        }
        widget.onHighlighted?.call();
        _controller.forward(from: 0);
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget._matches) return widget.child;
    final color = widget.highlightColor ?? AppColors.primaryColor;
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Overlay starts strong (t=1) and fades to nothing (t=0).
        final t = 1 - _controller.value;
        return DecoratedBox(
          position: widget.foreground
              ? DecorationPosition.foreground
              : DecorationPosition.background,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            border: Border.all(
              color: color.withValues(alpha: 0.9 * t),
              width: 2,
            ),
            color: color.withValues(alpha: 0.12 * t),
          ),
          child: child,
        );
      },
    );
  }
}
