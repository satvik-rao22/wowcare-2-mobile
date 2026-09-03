import 'dart:async';

import 'package:wowcare/domain/features/communication/entities/messaging_connection_status.dart';

/// Tracks the realtime message subscription's health as a small state machine,
/// driven by the datasource's subscription lifecycle. Kept separate from the
/// Firestore plumbing so the transition rules are pure and unit-testable.
///
/// Emits only on an actual status change (distinct), and remembers whether the
/// current logical subscription has ever reached [MessagingConnectionStatus
/// .connected] so a transient error after a successful connect reports
/// `reconnecting` rather than a first-time `connecting`.
class MessagingConnectionTracker {
  final _controller =
      StreamController<MessagingConnectionStatus>.broadcast();

  MessagingConnectionStatus _status = MessagingConnectionStatus.connecting;
  bool _everConnected = false;

  MessagingConnectionStatus get status => _status;
  Stream<MessagingConnectionStatus> get stream => _controller.stream;

  void _set(MessagingConnectionStatus next) {
    if (next == _status) return;
    _status = next;
    if (!_controller.isClosed) _controller.add(next);
  }

  /// A brand-new logical subscription is starting (new conversation opened or a
  /// full re-subscribe). Resets the "ever connected" memory.
  void onNewSubscription() {
    _everConnected = false;
    _set(MessagingConnectionStatus.connecting);
  }

  /// A server snapshot arrived — the subscription is live and healthy.
  void onConnected() {
    _everConnected = true;
    _set(MessagingConnectionStatus.connected);
  }

  /// A transient error triggered a backoff retry or an auth-recovery wait.
  /// Reads as `reconnecting` only if we had connected at least once; otherwise
  /// we are still making the first connection.
  void onRetrying() {
    _set(_everConnected
        ? MessagingConnectionStatus.reconnecting
        : MessagingConnectionStatus.connecting);
  }

  /// Retries exhausted — live sync is down (REST fallback may still serve data).
  void onOffline() => _set(MessagingConnectionStatus.offline);

  Future<void> dispose() => _controller.close();
}
