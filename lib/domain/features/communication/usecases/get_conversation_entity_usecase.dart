import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/entities/conversation_entity.dart';
import '../repositories/conversation_entity_repository.dart';

class GetConversationEntityUseCase {
  final ConversationEntityRepository _repository;

  GetConversationEntityUseCase(this._repository);

  Future<Either<Failure, ConversationEntity>> call(String conversationCode) {
    return _repository.getConversation(conversationCode);
  }
}
