import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../repositories/communication_repository.dart';

/// Per-conversation unread counts, keyed by conversation code — backed by
/// the confirmed-reliable `/messages/unread-per-conversation` endpoint.
/// Legacy-stack counterpart of [GetUnreadCountsPerConversationUseCase].
class GetLegacyUnreadCountsPerConversationUseCase {
  final CommunicationRepository _repository;

  GetLegacyUnreadCountsPerConversationUseCase(this._repository);

  Future<Either<Failure, Map<String, int>>> call() {
    return _repository.getUnreadCountsPerConversation();
  }
}
