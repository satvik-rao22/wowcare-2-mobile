import '../entities/messaging_connection_status.dart';
import '../repositories/messaging_connection_repository.dart';

/// Streams the realtime message subscription's health for the thread UI.
class WatchMessagingConnectionUseCase {
  WatchMessagingConnectionUseCase(this._repository);

  final MessagingConnectionRepository _repository;

  Stream<MessagingConnectionStatus> call() =>
      _repository.watchConnectionStatus();

  /// Current status, for seeding the UI before the first stream event.
  MessagingConnectionStatus get current => _repository.currentStatus;
}
