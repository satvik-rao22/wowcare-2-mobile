import 'package:flutter_test/flutter_test.dart';
import 'package:wowcare/data/features/communication/realtime/messaging_connection_tracker.dart';
import 'package:wowcare/domain/features/communication/entities/messaging_connection_status.dart';

void main() {
  late MessagingConnectionTracker tracker;

  setUp(() => tracker = MessagingConnectionTracker());
  tearDown(() => tracker.dispose());

  test('starts in connecting', () {
    expect(tracker.status, MessagingConnectionStatus.connecting);
  });

  test('connecting → connected on first snapshot', () {
    tracker.onConnected();
    expect(tracker.status, MessagingConnectionStatus.connected);
  });

  test('a retry BEFORE ever connecting stays connecting (first connect)', () {
    tracker.onRetrying();
    expect(tracker.status, MessagingConnectionStatus.connecting);
  });

  test('a retry AFTER connecting reports reconnecting', () {
    tracker.onConnected();
    tracker.onRetrying();
    expect(tracker.status, MessagingConnectionStatus.reconnecting);
  });

  test('give-up reports offline', () {
    tracker.onConnected();
    tracker.onOffline();
    expect(tracker.status, MessagingConnectionStatus.offline);
  });

  test('reconnecting → connected when a snapshot returns', () {
    tracker.onConnected();
    tracker.onRetrying();
    tracker.onConnected();
    expect(tracker.status, MessagingConnectionStatus.connected);
  });

  test('onNewSubscription resets the ever-connected memory', () {
    tracker.onConnected();
    tracker.onNewSubscription();
    // A retry now is a first-time connect again, not a reconnect.
    tracker.onRetrying();
    expect(tracker.status, MessagingConnectionStatus.connecting);
  });

  test('stream emits only distinct transitions', () async {
    final seen = <MessagingConnectionStatus>[];
    final sub = tracker.stream.listen(seen.add);

    tracker.onConnected();
    tracker.onConnected(); // duplicate — no emit
    tracker.onRetrying(); // reconnecting
    tracker.onOffline();

    await Future<void>.delayed(Duration.zero);
    await sub.cancel();

    expect(seen, [
      MessagingConnectionStatus.connected,
      MessagingConnectionStatus.reconnecting,
      MessagingConnectionStatus.offline,
    ]);
  });
}
