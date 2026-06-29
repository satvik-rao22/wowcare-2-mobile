import 'package:flutter/material.dart';

import '../../../../../app/theme/colors.dart';

/// Thin retry chip that grows in directly above a dashboard card when that
/// card's data failed to load, pushing the card down and sitting flush
/// against its top edge (rounded on top, flat where it meets the card) so
/// the two read as one connected shape.
///
/// Wrap any card with [DashboardCardErrorOverlay] and pass the card's own
/// error flag (from its existing Cubit state) plus a retry callback that
/// re-invokes that same Cubit's existing load method. No new Cubits or
/// state are introduced; this widget only renders and tracks the transient
/// "is this retry tap in flight" flag locally.
class DashboardCardErrorOverlay extends StatefulWidget {
  const DashboardCardErrorOverlay({
    super.key,
    required this.show,
    required this.child,
    required this.onRetry,
    this.label = "Couldn't refresh",
    this.retryLabel = 'Tap to retry',
  });

  /// Whether the owning Cubit is currently in an error state.
  final bool show;

  /// The card itself — rendered unchanged, on top of the strip.
  final Widget child;

  /// Re-invokes the card's existing Cubit reload method. Scoped to this
  /// card only — must not touch sibling cards or the dashboard coordinator.
  final Future<void> Function() onRetry;

  final String label;
  final String retryLabel;

  @override
  State<DashboardCardErrorOverlay> createState() =>
      _DashboardCardErrorOverlayState();
}

class _DashboardCardErrorOverlayState extends State<DashboardCardErrorOverlay>
    with SingleTickerProviderStateMixin {
  static const double _stripHeight = 36;
  static const Duration _duration = Duration(milliseconds: 280);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _duration,
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<double> _reveal = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOutCubic,
  );

  bool _isRetrying = false;

  @override
  void initState() {
    super.initState();
    if (widget.show) _controller.value = 1;
  }

  @override
  void didUpdateWidget(DashboardCardErrorOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.show && !oldWidget.show) {
      _controller.forward();
    } else if (!widget.show && oldWidget.show) {
      _controller.reverse();
      _isRetrying = false;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      await widget.onRetry();
    } finally {
      // On success the owning Cubit flips `show` to false via
      // didUpdateWidget above, which resets `_isRetrying` and reverses the
      // animation. This finally-block only covers the case where the retry
      // failed again and `show` stays true, so the spinner must still clear.
      if (mounted && _isRetrying) {
        setState(() => _isRetrying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Grows in from zero height above the card, pushing the card down
        // to make room — clipped during the animation so it appears to
        // unfurl from the top rather than popping in at full size.
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return ClipRect(
              child: Align(
                alignment: Alignment.topCenter,
                heightFactor: _reveal.value,
                child: Opacity(
                  opacity: _fade.value,
                  child: SizedBox(
                    height: _stripHeight,
                    child: _RetryStrip(
                      label: widget.label,
                      retryLabel: widget.retryLabel,
                      isRetrying: _isRetrying,
                      onTap: _handleRetry,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        widget.child,
      ],
    );
  }
}

class _RetryStrip extends StatelessWidget {
  const _RetryStrip({
    required this.label,
    required this.retryLabel,
    required this.isRetrying,
    required this.onTap,
  });

  final String label;
  final String retryLabel;
  final bool isRetrying;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: isRetrying ? null : onTap,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.errorColor.withValues(alpha: 0.08),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(12),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Icon(Icons.error_outline, size: 14, color: AppColors.errorColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  '$label · $retryLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.errorColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 16,
                height: 16,
                child: isRetrying
                    ? CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.errorColor,
                      )
                    : InkWell(
                        onTap: onTap,
                        borderRadius: BorderRadius.circular(8),
                        child: Icon(
                          Icons.refresh,
                          size: 16,
                          color: AppColors.errorColor,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
