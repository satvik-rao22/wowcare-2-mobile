import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import 'package:wowcare/domain/features/communication/entities/enums.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';

class WatchConversationsUseCase {
  const WatchConversationsUseCase(this._repository);

  final ConversationEntityRepository _repository;

  Stream<List<ConversationEntity>> call({ConversationType? type}) {
    return _repository.watchConversations(type: type);
  }
}
