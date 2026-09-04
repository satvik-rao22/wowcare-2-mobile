import 'package:flutter/foundation.dart';

/// Where tapping a notification lands (12c).
///
/// Two answers, not one. Either there is a screen for it and the tap pushes
/// that location, or the module it belongs to has not been rebuilt yet and
/// the tap says so out loud. What it must never be is nothing: a row that
/// swallows a tap is indistinguishable from a broken one.
@immutable
sealed class NotificationDestination {
  const NotificationDestination();
}

/// A screen that exists: push [location], which is always an `AppRoutes` path.
@immutable
class NotificationRoute extends NotificationDestination {
  const NotificationRoute(this.location);

  final String location;

  @override
  bool operator ==(Object other) =>
      other is NotificationRoute && other.location == location;

  @override
  int get hashCode => location.hashCode;

  @override
  String toString() => 'NotificationRoute($location)';
}

/// The module this notification belongs to is not rebuilt yet, so the tap
/// reports that rather than opening a placeholder.
@immutable
class NotificationNotBuilt extends NotificationDestination {
  const NotificationNotBuilt();

  @override
  bool operator ==(Object other) => other is NotificationNotBuilt;

  @override
  int get hashCode => (NotificationNotBuilt).hashCode;

  @override
  String toString() => 'NotificationNotBuilt';
}
