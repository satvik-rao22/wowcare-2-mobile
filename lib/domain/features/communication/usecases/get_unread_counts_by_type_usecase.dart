import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../repositories/conversation_entity_repository.dart';

/// Per-conversation unread counts summed by conversation type — same
/// `/messages/unread-per-conversation` endpoint as
/// [GetUnreadCountsPerConversationUseCase], grouped differently. Used to
/// force an immediate, authoritative top-bar badge refresh right after a
/// conversation is marked read, instead of waiting for Firestore's own
/// aggregate stream to eventually catch up.
class GetUnreadCountsByTypeUseCase {
  final ConversationEntityRepository _repository;

  GetUnreadCountsByTypeUseCase(this._repository);

  Future<Either<Failure, Map<String, int>>> call() {
    return _repository.getUnreadCountsByType();
  }
}
