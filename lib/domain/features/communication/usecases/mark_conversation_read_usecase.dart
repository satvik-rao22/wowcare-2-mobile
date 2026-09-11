import 'package:dartz/dartz.dart';
import 'package:wowcare/core/errors/failures.dart';
import 'package:wowcare/domain/features/communication/repositories/conversation_entity_repository.dart';

class MarkConversationReadUseCase {
  final ConversationEntityRepository _repository;

  MarkConversationReadUseCase(this._repository);

  Future<Either<Failure, void>> call(String conversationCode) {
    return _repository.markConversationRead(conversationCode);
  }
}
