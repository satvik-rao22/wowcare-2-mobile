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
    this.highlightGradient,
    this.duration = const Duration(milliseconds: 3200),
    this.scrollOnHighlight = false,
    this.foreground = true,
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

  /// Single-color override. Ignored when [highlightGradient] is set. When
  /// neither is set, the built-in sunset gradient (see [_defaultGradient])
  /// is used.
  final Color? highlightColor;

  /// Gradient override for the flash border + fill. Defaults to
  /// [AppColors.primaryGradientColors] — the app's own brand gradient
  /// (bottom nav bar, drawer header) — so the highlight reads as an
  /// intentional "this is the one" accent rather than an arbitrary color,
  /// while still standing out against a plain card because it's a moving
  /// two-stop gradient + border, not the flat dark-plum wash that used to
  /// blend into headers/nav/buttons.
  final List<Color>? highlightGradient;

  final Duration duration;

  /// When true, the card scrolls itself into view (via its own context) on
  /// highlight — no external [GlobalKey] needed. Use for deeply-nested cards.
  final bool scrollOnHighlight;

  /// Paints the flash IN FRONT of [child] instead of behind it.
  ///
  /// Defaults to `true`: painting behind is invisible whenever the child's
  /// own layout covers the same rect with anything opaque-ish — an opaque
  /// full-bleed `Container` (`StaffStyleCard`), or (as found in the activity
  /// feed) just several layered/colored elements that collectively obscure
  /// it even with no single opaque layer. This bit us twice independently
  /// (`parent_billing_screen.dart`, `activity_daily_tab.dart`) before the
  /// default was flipped — foreground is translucent, so content still reads
  /// through; set this to `false` only for a card verified to render
  /// correctly with the tint behind it.
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

  static const List<Color> _defaultGradient = AppColors.primaryGradientColors;

  @override
  Widget build(BuildContext context) {
    if (!widget._matches) return widget.child;
    final colors = widget.highlightGradient ??
        (widget.highlightColor != null
            ? [widget.highlightColor!, widget.highlightColor!]
            : _defaultGradient);
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        // Overlay starts strong (t=1) and fades to nothing (t=0).
        final t = 1 - _controller.value;
        final painter = _GradientHighlightPainter(
          t: t,
          borderRadius: widget.borderRadius,
          colors: colors,
        );
        return CustomPaint(
          painter: widget.foreground ? null : painter,
          foregroundPainter: widget.foreground ? painter : null,
          child: child,
        );
      },
    );
  }
}

class _GradientHighlightPainter extends CustomPainter {
  _GradientHighlightPainter({
    required this.t,
    required this.borderRadius,
    required this.colors,
  });

  final double t;
  final double borderRadius;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );

    final fillColors = colors.map((c) => c.withValues(alpha: 0.28 * t)).toList();
    final fillPaint = Paint()
      ..shader = LinearGradient(
        colors: fillColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(rrect, fillPaint);

    final borderColors = colors.map((c) => c.withValues(alpha: t)).toList();
    const strokeWidth = 3.0;
    final borderRect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(borderRadius - strokeWidth / 2),
    );
    final borderPaint = Paint()
      ..shader = LinearGradient(
        colors: borderColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawRRect(borderRect, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _GradientHighlightPainter oldDelegate) =>
      oldDelegate.t != t ||
      oldDelegate.borderRadius != borderRadius ||
      oldDelegate.colors != colors;
}
