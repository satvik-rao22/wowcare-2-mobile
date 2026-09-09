import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/message.dart';
import 'package:wowcare/domain/features/communication/repositories/communication_repository.dart';

/// Persists an optimistic (sending/failed) [Message] into the local cache —
/// see [CommunicationRepository.cacheMessage].
class CacheMessageUseCase {
  final CommunicationRepository _repository;
  CacheMessageUseCase(this._repository);

  Future<Either<Failure, void>> call(String threadId, Message message) =>
      _repository.cacheMessage(threadId, message);
}

/// Removes a cached draft row by its local temp id — see
/// [CommunicationRepository.discardCachedMessage].
class DiscardCachedMessageUseCase {
  final CommunicationRepository _repository;
  DiscardCachedMessageUseCase(this._repository);

  Future<Either<Failure, void>> call(String messageId) =>
      _repository.discardCachedMessage(messageId);
}
