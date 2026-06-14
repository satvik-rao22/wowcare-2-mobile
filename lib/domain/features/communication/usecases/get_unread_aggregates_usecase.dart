import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import '../repositories/conversation_entity_repository.dart';

class GetUnreadAggregatesUseCase {
  final ConversationEntityRepository _repository;

  GetUnreadAggregatesUseCase(this._repository);

  Future<Either<Failure, Map<String, int>>> call() {
    return _repository.getUnreadAggregates();
  }
}
