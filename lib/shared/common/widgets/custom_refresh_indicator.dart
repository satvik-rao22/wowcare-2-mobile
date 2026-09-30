import 'package:flutter/material.dart';
import 'package:wowcare/core/theme/app_theme_config.dart';

/// Accepts nested vertical scrollables (e.g. [Column] + [ListView]) so pull-to-refresh
/// works when the scrollable is not the direct child of [RefreshIndicator].
bool _nestedVerticalScrollPredicate(ScrollNotification notification) {
  return notification.metrics.axis == Axis.vertical;
}

class CustomRefreshIndicator extends StatelessWidget {
  const CustomRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.displacement,
    this.notificationPredicate,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final double? displacement;

  /// Defaults to accepting any nested vertical [ScrollNotification] so refresh
  /// works with [Column] + [ListView] and with [SingleChildScrollView] empty states.
  final ScrollNotificationPredicate? notificationPredicate;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      backgroundColor: AppPalette.brand,
      color: AppPalette.onBrand,
      displacement: displacement ?? 24,
      onRefresh: onRefresh,
      notificationPredicate:
          notificationPredicate ?? _nestedVerticalScrollPredicate,
      child: child,
    );
  }
}
