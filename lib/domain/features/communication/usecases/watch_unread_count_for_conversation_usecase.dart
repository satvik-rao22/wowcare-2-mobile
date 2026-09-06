import '../repositories/conversation_entity_repository.dart';

class WatchUnreadCountForConversationUseCase {
  const WatchUnreadCountForConversationUseCase(this._repository);

  final ConversationEntityRepository _repository;

  Stream<int> call(String conversationCode) =>
      _repository.watchUnreadCountForConversation(conversationCode);
}
