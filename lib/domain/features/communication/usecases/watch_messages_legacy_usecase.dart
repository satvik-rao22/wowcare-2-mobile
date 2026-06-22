import '../entities/message.dart';
import '../repositories/communication_repository.dart';

/// Firestore delta stream for a single thread's messages — see
/// [CommunicationRepository.watchMessages] for the merge-into-Isar contract.
class WatchMessagesLegacyUseCase {
  final CommunicationRepository _repository;

  WatchMessagesLegacyUseCase(this._repository);

  Stream<List<Message>> call(String threadId) {
    return _repository.watchMessages(threadId);
  }
}
