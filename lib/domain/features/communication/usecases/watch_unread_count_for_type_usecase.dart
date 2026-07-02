import 'package:wowcare/domain/features/communication/entities/enums.dart';
import '../repositories/conversation_entity_repository.dart';

/// Lightweight per-type unread counter.
///
/// Reads directly from Firestore via the realtime data source — no Isar merge,
/// no full conversation list. Used by [UnreadBadgeCubit] so it does not
/// duplicate the [WatchConversationsUseCase] stream pipeline.
class WatchUnreadCountForTypeUseCase {
  const WatchUnreadCountForTypeUseCase(this._repository);

  final ConversationEntityRepository _repository;

  Stream<int> call(ConversationType type) =>
      _repository.watchUnreadCountForType(type);
}
