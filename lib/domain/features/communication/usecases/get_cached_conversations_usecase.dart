import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../entities/conversation.dart';
import '../repositories/communication_repository.dart';

class GetCachedConversationsUseCase {
  final CommunicationRepository _repository;

  GetCachedConversationsUseCase(this._repository);

  Future<Either<Failure, List<Conversation>>> call() {
    return _repository.loadCachedConversations();
  }
}
