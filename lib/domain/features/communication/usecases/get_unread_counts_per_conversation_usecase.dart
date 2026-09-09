import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';

/// Per-conversation unread counts, keyed by conversation code — backed by
/// the confirmed-reliable `/messages/unread-per-conversation` endpoint.
class GetUnreadCountsPerConversationUseCase {
  final ConversationEntityRepository _repository;

  GetUnreadCountsPerConversationUseCase(this._repository);

  Future<Either<Failure, Map<String, int>>> call() {
    return _repository.getUnreadCountsPerConversation();
  }
}
