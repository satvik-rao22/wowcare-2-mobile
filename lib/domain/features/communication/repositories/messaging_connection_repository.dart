import '../entities/messaging_connection_status.dart';

/// Exposes the realtime message subscription's health so presentation can tell
/// the user when live updates are degraded. Backed by the realtime datasource.
abstract class MessagingConnectionRepository {
  /// Emits on every change to the realtime connection status.
  Stream<MessagingConnectionStatus> watchConnectionStatus();

  /// The current status (for seeding UI before the first stream event).
  MessagingConnectionStatus get currentStatus;
}
