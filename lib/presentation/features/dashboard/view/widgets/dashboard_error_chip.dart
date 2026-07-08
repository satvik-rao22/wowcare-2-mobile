import 'package:flutter/material.dart';

/// Wraps a dashboard card. Previously it grew an inline "Couldn't refresh ·
/// Tap to retry" strip above the card when that card's Cubit was in an error
/// state; per product decision the dashboard no longer surfaces that chip, so
/// this now renders the card unchanged.
///
/// The constructor keeps its original parameters ([show], [onRetry], [label],
/// [retryLabel]) so existing call sites compile without changes — they're just
/// no longer rendered. Pull-to-refresh still lets users retry a failed card.
class DashboardCardErrorOverlay extends StatelessWidget {
  const DashboardCardErrorOverlay({
    super.key,
    required this.show,
    required this.child,
    required this.onRetry,
    this.label = "Couldn't refresh",
    this.retryLabel = 'Tap to retry',
  });

  /// Whether the owning Cubit is currently in an error state (no longer drives
  /// any UI, retained for call-site compatibility).
  final bool show;

  /// The card itself — rendered unchanged.
  final Widget child;

  /// Retained for call-site compatibility; no longer invoked from here.
  final Future<void> Function() onRetry;

  final String label;
  final String retryLabel;

  @override
  Widget build(BuildContext context) => child;
}
