import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';

class WatchTotalUnreadCountUseCase {
  const WatchTotalUnreadCountUseCase(this._repository);

  final ConversationEntityRepository _repository;

  Stream<int> call() => _repository.watchTotalUnreadCount();
}
