import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../repositories/communication_repository.dart';

class ClearMessagesCacheUseCase {
  final CommunicationRepository _repository;
  ClearMessagesCacheUseCase(this._repository);

  Future<Either<Failure, void>> call(String threadId) =>
      _repository.clearMessagesCache(threadId);
}

class ClearConversationsCacheUseCase {
  final CommunicationRepository _repository;
  ClearConversationsCacheUseCase(this._repository);

  Future<Either<Failure, void>> call() =>
      _repository.clearConversationsCache();
}
