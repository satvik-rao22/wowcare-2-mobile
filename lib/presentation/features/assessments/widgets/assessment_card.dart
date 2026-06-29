import 'package:flutter/material.dart';

/// The shared card shell for the Assessments module.
///
/// Replaces the old flat white + grey-hairline cards: a white surface with a
/// soft *accent-tinted* shadow, a thin accent border and a coloured left
/// accent strip — the same depth-and-colour language used by the Events and
/// Tasks cards. Tapping gives a subtle press-scale + ripple (the mobile
/// equivalent of the web design's `hover:shadow-md`).
class AssessmentCard extends StatefulWidget {
  const AssessmentCard({
    super.key,
    required this.child,
    required this.accent,
    this.onTap,
    this.padding = const EdgeInsets.all(14),
    this.borderRadius = 16,
    this.showAccentStrip = true,
    this.elevated = true,
  });

  final Widget child;

  /// Drives the border tint, shadow colour and left strip (usually a
  /// score-derived colour from [AssessmentUi.scoreAccent]).
  final Color accent;
  final VoidCallback? onTap;
  final EdgeInsets padding;
  final double borderRadius;
  final bool showAccentStrip;

  /// When false, drops the coloured shadow (for nested/embedded cards).
  final bool elevated;

  @override
  State<AssessmentCard> createState() => _AssessmentCardState();
}

class _AssessmentCardState extends State<AssessmentCard> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(widget.borderRadius);
    const stripWidth = 5.0;

    return AnimatedScale(
      scale: _down ? 0.975 : 1,
      duration: const Duration(milliseconds: 110),
      curve: Curves.easeOut,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: radius,
          border: Border.all(color: widget.accent.withValues(alpha: 0.22)),
          boxShadow: widget.elevated
              ? [
                  BoxShadow(
                    color: widget.accent.withValues(alpha: 0.13),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: widget.onTap,
            onHighlightChanged: widget.onTap == null
                ? null
                : (v) => setState(() => _down = v),
            splashColor: widget.accent.withValues(alpha: 0.08),
            highlightColor: widget.accent.withValues(alpha: 0.04),
            child: Stack(
              children: [
                if (widget.showAccentStrip)
                  PositionedDirectional(
                    start: 0,
                    top: 0,
                    bottom: 0,
                    child: Container(width: stripWidth, color: widget.accent),
                  ),
                Padding(
                  padding: widget.showAccentStrip
                      ? widget.padding.add(
                          const EdgeInsetsDirectional.only(start: stripWidth)
                              .resolve(Directionality.of(context)),
                        )
                      : widget.padding,
                  child: widget.child,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
