import 'package:wowcare/domain/features/communication/entities/message_entity.dart';
import '../repositories/message_entity_repository.dart';

/// Persists an optimistic [MessageEntity] to Isar immediately — before any
/// upload or network call runs — so it survives navigating away or the app
/// being killed mid-send.
class CacheDraftMessageUseCase {
  final MessageEntityRepository _repository;

  CacheDraftMessageUseCase(this._repository);

  Future<void> call(MessageEntity message) =>
      _repository.cacheDraftMessage(message);
}
