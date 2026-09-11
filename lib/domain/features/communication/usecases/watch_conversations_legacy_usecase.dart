import 'package:wowcare/domain/features/communication/entities/conversation.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

/// Firestore delta stream for the conversation list — see
/// [CommunicationRepository.watchConversations] for the merge-into-Isar
/// contract.
class WatchConversationsLegacyUseCase {
  final CommunicationRepository _repository;

  WatchConversationsLegacyUseCase(this._repository);

  Stream<List<Conversation>> call({String? type}) {
    return _repository.watchConversations(type: type);
  }
}
