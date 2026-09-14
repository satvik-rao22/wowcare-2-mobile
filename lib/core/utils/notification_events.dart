import 'package:flutter/foundation.dart';

/// Lightweight global signal fired when the user's notification inbox changes
/// (a new push arrives, or the live Firestore notifications collection ticks).
/// An open Notification Center listens to [inboxChanged] and reloads its list so
/// it stays live — the same pattern as [BillingEvents].
///
/// The bell badge count is handled separately (REST) — this only tells an open
/// list to refresh.
class NotificationEvents {
  NotificationEvents._();

  /// Bumped once per inbox change.
  static final ValueNotifier<int> inboxChanged = ValueNotifier<int>(0);

  /// Fire when a new notification arrives / the inbox changes.
  static void notifyChanged() => inboxChanged.value++;
}
